CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_reply_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  user_likes INTEGER NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Mike', 'Shin'),
  ('Stefan', 'Cardenas');

INSERT INTO
  questions (title, body, author_id)
VALUES
  (('CODING BOOTCAMP'), ('what is app appacademy?'),
  (SELECT id FROM users WHERE fname = 'Mike' AND lname = 'Shin'));

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'Mike' AND lname = 'Shin'),
  (SELECT id FROM questions WHERE title = 'CODING BOOTCAMP')),
  ((SELECT id FROM users WHERE fname = 'Stefan' AND lname = 'Cardenas'),
  (SELECT id FROM questions WHERE title = 'CODING BOOTCAMP'));

INSERT INTO
  replies (question_id, parent_reply_id, user_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = 'CODING BOOTCAMP'),
  NULL, (SELECT id FROM users WHERE fname = 'Mike' AND lname = 'Shin'),
  'Nevermind. I answered my own question. :)'),
   ((SELECT id FROM questions WHERE title = 'CODING BOOTCAMP'),
  1, (SELECT id FROM users WHERE fname = 'Mike' AND lname = 'Shin'),
  'Did you now? -_- ');

INSERT INTO
  question_likes (question_id, user_id, user_likes)
VALUES
  ((SELECT id FROM questions WHERE title = 'CODING BOOTCAMP'),
  (SELECT id FROM users WHERE fname = 'Mike' AND lname = 'Shin'), 7);
