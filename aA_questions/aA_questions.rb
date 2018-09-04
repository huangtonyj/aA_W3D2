require 'sqlite3'
require 'singleton'

class QuestionsDB < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end


class Users
  attr_accessor :fname, :lname

  def self.all
    users = QuestionsDB.instance.execute("SELECT * FROM users")
    users.map { |user| Users.new(user) }
  end

  def self.find_by_id(id)
    user = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT * FROM users WHERE id = ?
    SQL
    return nil unless user.length > 0
    Users.new(user.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
end


class Questions
  attr_accessor :title, :body, :author_id

  def self.all
    questions = QuestionsDB.instance.execute("SELECT * FROM questions")
    questions.map { |question| Questions.new(question) }
  end

  def self.find_by_id(id)
    question = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT * FROM questions WHERE id = ?
    SQL
    return nil unless question.length > 0
    Questions.new(question.first)
  end

  def self.find_by_author_id(author_id)
    questions = QuestionsDB.instance.execute(<<-SQL, author_id)
      SELECT * FROM questions WHERE author_id = ?
    SQL
    return nil unless questions.length > 0
    questions.map{|question| Questions.new(question)}
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end
end


class QuestionsFollow
  attr_accessor :user_id, :question_id

  def self.all
    question_follows = QuestionsDB.instance.execute("SELECT * FROM question_follows")
    question_follows.map { |question_follow| QuestionsFollow.new(question_follow) }
  end

  def self.find_by_id(id)
    question_follow = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT * FROM question_follows WHERE id = ?
    SQL
    return nil unless question_follow.length > 0
    QuestionsFollow.new(question_follow.first)
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end


class Replies
  attr_accessor :question_id, :parent_reply_id, :author_id, :body

  def self.all
    replies = QuestionsDB.instance.execute("SELECT * FROM replies")
    replies.map { |reply| Replies.new(reply) }
  end

  def self.find_by_id(id)
    reply = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT * FROM replies WHERE id = ?
    SQL
    return nil unless reply.length > 0
    Replies.new(reply.first)
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
    @author_id = options['author_id']
    @body = options['body']
  end
end


class QuestionLikes
  attr_accessor :user_id, :question_id

  def self.all
    question_likes = QuestionsDB.instance.execute("SELECT * FROM question_likes")
    question_likes.map { |question_like| QuestionLikes.new(question_like) }
  end

  def self.find_by_id(id)
    question_like = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT * FROM question_likes WHERE id = ?
    SQL
    return nil unless question_like.length > 0
    QuestionLikes.new(question_like.first)
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end
