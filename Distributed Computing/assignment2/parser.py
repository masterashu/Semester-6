import urllib
import requests
import sqlite3
import json
import os
import time
from celery import Celery
from queries import (
    CREATE_ANSWERS,
    CREATE_QUESTIONS,
    CREATE_RELATED,
    INSERT_ANSWERS,
    INSERT_QUESTIONS,
    INSERT_RELATED,
)

app = Celery("parser", broker="pyamqp://guest@localhost//")

BASE_DIR = os.getcwd() + "/info"
DATA_DIR = os.getcwd() + "/data"

# Using sqlite for easy submission
# Can use MySQL/PostgreSQL for concurrent writes
# from celery workers
db = sqlite3.connect(f"{BASE_DIR}/db.sqlite3")
_, _, filenames = next(os.walk(DATA_DIR))

KEY = "TchQeZI6Oi1Lh6Ckq5DUtg(("


def setup():
    cur = db.cursor()
    cur.execute(CREATE_QUESTIONS)
    cur.execute(CREATE_ANSWERS)
    cur.execute(CREATE_RELATED)
    cur.close()


def insert_questions(questions):
    cur = db.cursor()
    for question in questions:
        try:
            cur.execute(INSERT_QUESTIONS, question)
        except:
            continue
    db.commit()
    cur.close()


def question_to_data(question):
    return tuple(
        map(
            str,
            (
                question["title"],
                question["question_id"],
                question.get("down_votes_count", 0),
                question.get("up_votes_count", 0),
                question.get("answer_count", 0),
                1 if question.get("is_answered", False) else 0,
                1 if question.get("accepted_answer_id", False) else 0,
                question.get("body", "Noo body"),
                question.get("owner", {}).get("user_id", 1),
            ),
        )
    )


def insert_answers(answers):
    cur = db.cursor()
    for answer in answers:
        try:
            cur.executemany(INSERT_ANSWERS, answer)
        except:
            continue
    db.commit()
    cur.close()


def answer_to_data(answer):
    return tuple(
        map(
            str,
            (
                answer["answer_id"],
                answer.get("body", "Noo body"),
                answer["question_id"],
                answer.get("down_votes_count", 0),
                answer.get("up_votes_count", 0),
                answer.get("owner", {}).get("user_id", 1),
                1 if answer.get("is_accepted", False) else 0,
            ),
        )
    )


def insert_related(related_questions):
    cur = db.cursor()
    cur.execute(INSERT_RELATED, related_questions)
    db.commit()
    cur.close()


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


@app.task
def loadData(data_file):
    with open(f"{DATA_DIR}/{data_file}", "r") as df:
        try:
            data = json.loads(df.read())
        except Exception as e:
            print(e)
            return
    try:
        insert_questions(map(question_to_data, data))
    except Exception as e:
        print(e)

    for question in data:
        load_answers(question)

        # get related.
        # try:
        rqdata = requests.get(get_related([question["question_id"]])).json()
        insert_questions(map(question_to_data, rqdata["items"]))
        for rqquestion in rqdata["items"]:
            try:
                load_answers(rqquestion)
                insert_related(
                    (
                        str(question["question_id"]),
                        str(rqquestion["question_id"]),
                    )
                )
                insert_related(
                    (
                        str(rqquestion["question_id"]),
                        str(question["question_id"]),
                    )
                )
            except Exception as e:
                print(e)
                continue


def load_answers(question):
    try:
        insert_answers(map(answer_to_data, question["answers"]))
    except:
        pass


def upload_to_queue():
    limit = 1
    # print(filenames[:10])
    for i, data_file in enumerate(filenames):
        if i >= limit:  # Only for local testing.
            print("stopping...")
            break
        if not os.path.isfile(f"{DATA_DIR}/{data_file}"):
            continue
        loadData.delay(data_file)


if __name__ == "__main__":
    setup()  # Do once
    upload_to_queue()
    db.close()
