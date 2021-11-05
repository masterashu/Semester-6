CREATE_QUESTIONS = """
CREATE TABLE IF NOT EXISTS "questions" ( \
	"title"	TEXT NOT NULL, \
	"id"	INTEGER NOT NULL UNIQUE, \
	"downvotes"	INTEGER NOT NULL, \
	"upvotes"	INTEGER NOT NULL, \
	"answers" INTEGER NOT NULL, \
	"is_answered"	INTEGER NOT NULL, \
	"is_accepted"	INTEGER NOT NULL, \
	"body"	INTEGER NOT NULL, \
	"user_id"	INTEGER NOT NULL, \
	PRIMARY KEY("id") \
);"""

INSERT_QUESTIONS = '''INSERT INTO "questions" ("title", "id", "downvotes", "upvotes", "answers", "is_answered", "is_accepted", "body", "user_id") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ? );'''

CREATE_ANSWERS = """CREATE TABLE IF NOT EXISTS "answers" ( \
	"id"	INTEGER NOT NULL UNIQUE, \
	"body"	TEXT NOT NULL, \
	"question_id"	INTEGER NOT NULL, \
	"downvotes"	INTEGER NOT NULL, \
	"upvotes"	INTEGER NOT NULL, \
	"user_id"	INTEGER NOT NULL, \
	"is_accepted"	INTEGER NOT NULL, \
	PRIMARY KEY("id"), \
	FOREIGN KEY("question_id") REFERENCES "questions"("id") \
);"""

INSERT_ANSWERS = '''INSERT INTO "answers" ("id", "body", "question_id", "downvotes", "upvotes", "user_id", "is_accepted" ) VALUES (?, ?, ?, ?, ?, ?, ? );'''

CREATE_RELATED = """CREATE TABLE IF NOT EXISTS "related_questions" ( \
	"question1"	INTEGER NOT NULL, \
	"question2"	INTEGER NOT NULL, \
	FOREIGN KEY("question2") REFERENCES "questions"("id"), \
	FOREIGN KEY("question1") REFERENCES "questions"("id") \
);"""

INSERT_RELATED = '''INSERT INTO "related_questions" ("question1", "question2" ) VALUES (?, ? );'''

LIST_RANDOM_QUESTIONS = '''SELECT * FROM "questions" ORDER BY RANDOM() LIMIT 10;'''

FIND_QUESTION = '''SELECT COUNT(*) FROM "questions" WHERE id=?;'''

GET_QUESTION_BY_ID = '''SELECT \
questions.upvotes, questions.downvotes, \
	questions.is_answered, questions.answers, \
	questions.is_accepted \
FROM \
questions \
WHERE \
	questions.id=?'''

GET_QUESTION_BODY_BY_ID = '''SELECT body FROM questions WHERE questions.id=?'''

GET_RELATED_DATA = '''SELECT \
	questions.upvotes, questions.downvotes, \
	questions.is_answered, questions.answers, \
	questions.is_accepted 
FROM \
	questions, related_questions \
WHERE \
	questions.id=related_questions.question1 \
	AND related_questions.question2=?;'''
