require 'singleton'
require 'sqlite3'
require 'byebug'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')

    self.results_as_hash = true

    self.type_translation = true
  end
end

class User
  def self.all
    results = QuestionsDatabase.instance.execute('SELECT * FROM users')
    results.map { |result| User.new(result) }
  end

  attr_accessor :id, :fname, :lname

  def initialize(options = {})
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def create
    raise 'already saved!' unless self.id.nil?

    params = [self.fname, self.lname]
    QuestionsDatabase.instance.execute(<<-SQL, *params)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def self.find_by(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        users.id = ?
    SQL

    User.new(results[0])
  end

  def self.find_by_name(fname, lname)

    params = [fname, lname]
    results = QuestionsDatabase.instance.execute(<<-SQL, *params)
      SELECT
        *
      FROM
        users
      WHERE
        users.fname = ? AND users.lname = ?
    SQL

    User.new(results[0])
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Reply.find_by_user_id(self.id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(self.id)
  end
end

class Question
  attr_accessor :id, :title, :body, :author_id

  def initialize(options = {})
    @id, @title, @body, @author_id =
      options.values_at('id', 'title', 'body', 'author_id')
  end

  def create
    raise 'already saved!' unless self.id.nil?

    params = [self.title, self.body, self.author_id]
    QuestionsDatabase.instance.execute(<<-SQL, *params)
      INSERT INTO
        questions (title, body, author_id)
      VALUES
        (?, ?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def self.find_by(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.id = ?
    SQL

    Question.new(results[0])
  end

  def self.find_by_author_id(author_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.author_id = ?
    SQL

    results.map {|result| Question.new(result) }
  end

  def author
    user_id = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        author_id
      FROM
        questions
      WHERE
        questions.id = ?
    SQL
    id = user_id[0]['author_id']
    User.find_by(id)
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

  def followers
    QuestionFollows.followers_for_question(self.id)
  end
end



class QuestionFollows
  attr_accessor :id, :user_id, :question_id

  def initialize(options = {})
    @id, @user_id, @question_id =
      options.values_at('id', 'user_id', 'question_id')
  end

  def create
    raise 'already saved!' unless self.id.nil?

    params = [self.user_id, self.question_id]
    QuestionsDatabase.instance.execute(<<-SQL, *params)
      INSERT INTO
        questions (user_id, question_id)
      VALUES
        (?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def self.find_by(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        question_follows.id = ?
    SQL

    QuestionFollows.new(results[0])
  end

  def self.followers_for_question(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT DISTINCT
        *
      FROM
        users
      JOIN question_follows ON users.id = question_follows.user_id
      WHERE
        question_follows.question_id = ?
    SQL

    users.map {|user| User.new(user) }
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT DISTINCT
        *
      FROM
        questions
      JOIN question_follows ON questions.id = question_follows.question_id
      JOIN users ON uesrs.id = question_follows.user_id
      WHERE
        question_follows.user_id = ?
    SQL

    questions.map {|question| Question.new(question)}
  end

  def self.most_followed_questions(n)
    most_questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT DISTINCT
        COUNT(user_id), question_id
      FROM
        question_follows
      GROUP BY
        question_id
      ORDER BY DESC
      LIMIT ?
    SQL
  end

end



class Reply
  attr_accessor :id, :question_id, :parent_reply_id, :user_id, :body

  def initialize(options = {})
    @id, @question_id, @parent_reply_id, @user_id, @body=
      options.values_at('id', 'question_id', 'parent_reply_id', 'user_id', 'body')
  end

  def create
    raise 'already saved!' unless self.id.nil?

    params = [self.question_id, self.parent_reply_id, self.user_id, self.body]
    QuestionsDatabase.instance.execute(<<-SQL, *params)
      INSERT INTO
        replies (question_id, parent_reply_id, user_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def self.find_by(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.id = ?
    SQL

    Reply.new(results[0])
  end

  def self.find_by_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.user_id = ?
    SQL

    results.map { |result| Reply.new(result) }
  end

  def self.find_by_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.question_id = ?
    SQL

    results.map { |result| Reply.new(result)}
  end

  def author
    User.find_by(self.user_id)
  end

  def question
    question_id = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        question_id
      FROM
        replies
      WHERE
        replies.id = ?
    SQL

    id = question_id[0]['question_id']
    User.find_by(id)
  end

  def parent_reply
    return nil unless self.parent_reply_id
    parent_reply_inf = QuestionsDatabase.instance.execute(<<-SQL, self.parent_reply_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.id = ?
    SQL

    Reply.new(parent_reply_inf[0])
  end

  def child_replies
    replies = Question.find_by(self.question.id).replies
    replies.each_with_index do |reply, idx|
      if self.body == reply.body && !replies[idx + 1].nil?
        return replies[idx + 1]
      end
    end

    nil
  end
end

class QuestionLikes
  attr_accessor :id, :question_id, :user_id, :user_likes

  def initialize(options = {})
    @id, @question_id, @user_id, @user_likes=
      options.values_at('id', 'question_id', 'user_id', 'user_likes')
  end

  def create
    raise 'already saved!' unless self.id.nil?

    params = [self.question_id, self.user_id, self.user_likes]
    QuestionsDatabase.instance.execute(<<-SQL, *params)
      INSERT INTO
        replies (question_id, user_id, user_likes)
      VALUES
        (?, ?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def self.find_by(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        question_likes.id = ?
    SQL

    QuestionLikes.new(results[0])
  end
end
