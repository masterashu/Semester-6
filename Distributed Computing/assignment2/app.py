from flask import Flask, render_template, request
import requests
from queries import (
    FIND_QUESTION,
    GET_QUESTION_BODY_BY_ID,
    GET_QUESTION_BY_ID,
    GET_RELATED_DATA,
    LIST_RANDOM_QUESTIONS,
)
from math import sqrt, log
import os
import urllib
import sqlite3

KEY = "TchQeZI6Oi1Lh6Ckq5DUtg(("

BASE_DIR = os.getcwd() + "/info"

app = Flask(__name__)


def get_random_questions():
    db = sqlite3.connect(f"{BASE_DIR}/db.sqlite3")
    cur = db.cursor()
    x = list(cur.execute(LIST_RANDOM_QUESTIONS))
    cur.close()
    return x


def calculate_difficulty_score(related_data):
    # (upvotes, downvotes, is_answered, answers_count, is_accepted)[]
    scores = []
    for data in related_data:
        scores += [
            (
                (1 / 5)
                * (sqrt(25 * int(data[3])) + 1 / (0.03 + log(1 + 0.1 * int(data[3]))))
                * (int(data[0]) * 2 - int(data[1]))
            )
            + 0.1 * sqrt(int(data[3])) * (int(data[0]) * 2 - int(data[1]))
        ]
    return {
        "score": 0 if len(scores) == 0 else sum(scores) / len(scores),
    }


def get_url(questions_links, page=1):
    ids = ";".join(list(map(str, questions_links)))
    base_url = f"https://api.stackexchange.com/2.2/questions/{ids}"
    url = urllib.parse.urlparse(base_url)
    query = dict(
        order="desc",
        sort="activity",
        key=KEY,
        site="stackoverflow",
        **{"filter": "!)TIzdW64e.WAJj7_MxDO79L7.0zdKS6VeaO)s(ByEn0bGILUCtQtSUQ)T"},
    )
    query.update({"page": page})
    url = url._replace(query=urllib.parse.urlencode(query))
    return urllib.parse.urlunparse(url)


def get_related(questions_links, page=1):
    ids = ";".join(map(str, questions_links))
    base_url = f"https://api.stackexchange.com/2.2/questions/{ids[0]}/related/"
    url = urllib.parse.urlparse(base_url)
    query = dict(
        order="desc",
        sort="activity",
        key=KEY,
        site="stackoverflow",
        **{"filter": "!)TIzdW64e.WAJj7_MxDO79L7.0zdKS6WWds-pFnldWgGbLdoft9f*s_)y"},
    )
    query.update({"page": page})
    url = url._replace(query=urllib.parse.urlencode(query))
    return urllib.parse.urlunparse(url)


def question_to_data(question):
    return tuple(
        map(
            int,
            (
                question.get("down_votes_count", 0),
                question.get("up_votes_count", 0),
                question.get("answer_count", 0),
                1 if question.get("is_answered", False) else 0,
                1 if question.get("accepted_answer_id", False) else 0,
            ),
        )
    )


@app.route("/")
def home():
    data = get_random_questions()
    return render_template("home.html", questions=data)


@app.route("/difficulty")
def search():
    question_id = request.args.get("question-id")
    db = sqlite3.connect(f"{BASE_DIR}/db.sqlite3")
    cur = db.cursor()
    # load data from Sqlite
    x = list(cur.execute(FIND_QUESTION, (question_id,)))[0][0]
    print(x)
    cur.close()
    if int(x) == 1:
        # SQL Question Data
        cur = db.cursor()
        x = tuple(cur.execute(GET_QUESTION_BY_ID, (question_id,)))
        y = list(cur.execute(GET_RELATED_DATA, (question_id,)))
        question_body = tuple(cur.execute(GET_QUESTION_BODY_BY_ID, (question_id,)))[0]
        cur.close()
        question_score = calculate_difficulty_score(x)
        related_question_score = calculate_difficulty_score(y)
        question_data = x[0]
    else:
        # Fall back to API
        # get question
        question = requests.get(get_url([question_id])).json()
        print(question)
        print(list(map(question_to_data, question["items"])))
        question_score = calculate_difficulty_score(
            map(question_to_data, question["items"])
        )
        # get related
        related = requests.get(get_url([question_id])).json()
        print(list(map(question_to_data, related["items"])))
        related_question_score = calculate_difficulty_score(
            map(question_to_data, related["items"])
        )
        question_data = question_to_data(question)
        question_body = question["items"][0]["body"]
    details = {
        "score": f"{related_question_score['score'] + question_score['score'] :.2f}",
    }

    return render_template(
        "difficulty.html",
        question_id=question_id,
        details=details,
        questions=get_random_questions(),
        question_body=question_body,
        question_data=question_data,
    )
