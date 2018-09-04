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

  def self.find_by_name(fname,lname)
    users = QuestionsDB.instance.execute(<<-SQL, fname, lname)
      SELECT * FROM users WHERE fname = ? AND lname = ?
    SQL
    return nil unless users.length > 0
    users.map{|user| Users.new(user)}
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    Questions.find_by_author_id(@id)
  end

  def authored_replies
    Replies.find_by_user_id(@id)
  end

  def followed_questions
    QuestionsFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLikes.liked_questions_for_user_id(@id)
  end

  def average_karma
    karma = QuestionsDB.instance.execute(<<-SQL, @id)
      SELECT AVG(likes) as avg_likes
      FROM
        (SELECT questions.id, questions.author_id, COUNT(question_likes.user_id) AS likes
        FROM questions
        LEFT JOIN question_likes ON questions.id = question_likes.question_id
        GROUP BY questions.id) AS sub_query
      WHERE sub_query.author_id = ?
      GROUP BY sub_query.author_id
    SQL
    karma.first['avg_likes']
  end

  def save
    if @id
      #update
      QuestionsDB.instance.execute(<<-SQL, @fname, @lname, @id)
        UPDATE users
        SET fname = ?, lname =?
        WHERE id = ?
      SQL
      puts "Update Successful"
    else
      # Insert
      QuestionsDB.instance.execute(<<-SQL, @fname, @lname)
        INSERT INTO users (fname, lname)
        VALUES (?, ?)
      SQL
      @id = QuestionsDB.instance.last_insert_row_id
    end
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

  def self.most_followed(n)
    QuestionsFollow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLikes.most_liked_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def author
    Users.find_by_id(@author_id)
  end

  def replies
    Replies.find_by_question_id(@id)
  end

  def followers
    QuestionsFollow.followers_for_question_id(@id)
  end

  def likers
    QuestionLikes.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLikes.num_likes_for_question_id(@id)
  end

  def save
    if @id
      #update
      QuestionsDB.instance.execute(<<-SQL, @title, @body, @author_id, @id)
        UPDATE questions
        SET title = ?,
          body = ?,
          author_id = ?
        WHERE id = ?
      SQL
      puts "Update Successful"
    else
      # Insert
      QuestionsDB.instance.execute(<<-SQL, @title, @body, @author_id)
        INSERT INTO questions (title, body, author_id)
        VALUES (?, ?, ?)
      SQL
      @id = QuestionsDB.instance.last_insert_row_id
    end
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

  def self.followers_for_question_id(question_id)
    followers = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT users.*
      FROM users
      JOIN question_follows ON question_follows.user_id = users.id
      WHERE question_id = ?
    SQL
    return nil if followers.empty?
    followers.map {|follower| Users.new(follower)}
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT questions.*
      FROM questions
      JOIN question_follows ON questions.id = question_follows.question_id
      WHERE question_follows.user_id = ?
    SQL
    return nil if questions.empty?
    questions.map {|question| Questions.new(question)}
  end

  def self.most_followed_questions(n)
    questions = QuestionsDB.instance.execute(<<-SQL, n)
      SELECT questions.*
      FROM questions
      JOIN question_follows ON questions.id = question_follows.question_id
      GROUP BY question_id
      ORDER BY COUNT(user_id) DESC
      LIMIT ?
    SQL
    return nil if questions.empty?
    questions.map {|question| Questions.new(question)}
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

  def self.find_by_user_id(user_id)
    replies = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT * FROM replies WHERE author_id = ?
    SQL
    return nil unless replies.length > 0
    replies.map{|reply| Replies.new(reply)}
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT * FROM replies WHERE question_id = ?
    SQL
    return nil unless replies.length > 0
    replies.map{|reply| Replies.new(reply)}
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
    @author_id = options['author_id']
    @body = options['body']
  end

  def author
    Users.find_by_id(@author_id)
  end

  def question
    Questions.find_by_id(@question_id)
  end

  def parent_reply
    Replies.find_by_id(@parent_reply_id)
  end

  def child_replies
    replies = QuestionsDB.instance.execute(<<-SQL, @id)
      SELECT *
      FROM replies
      WHERE parent_reply_id = ?
    SQL
    return nil unless replies.length > 0
    replies.map {|reply| Replies.new(reply)}
  end

  def save
    if @id
      #update
      QuestionsDB.instance.execute(<<-SQL, @question_id, @parent_reply_id, @author_id, @body, @id)
        UPDATE replies
        SET question_id = ?,
          parent_reply_id = ?,
          author_id = ?,
          body = ?
        WHERE id = ?
      SQL
      puts "Update Successful"
    else
      # Insert
      QuestionsDB.instance.execute(<<-SQL, @question_id, @parent_reply_id, @author_id, @body)
        INSERT INTO replies (question_id, parent_reply_id, author_id, body)
        VALUES (?, ?, ?, ?)
      SQL
      @id = QuestionsDB.instance.last_insert_row_id
    end
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

  def self.likers_for_question_id(question_id)
    users = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT users.*
      FROM users
      JOIN question_likes
      ON users.id = question_likes.user_id
      WHERE question_id = ?
    SQL
    return nil unless users.length > 0
    users.map {|user| Users.new(user)}
  end

  def self.num_likes_for_question_id(question_id)
    num_likes = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT COUNT(*) AS num_likes
      FROM question_likes
      WHERE question_id = ?
    SQL
    num_likes[0]['num_likes']
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT questions.*
      FROM questions
      JOIN question_likes
      ON questions.id = question_likes.question_id
      WHERE user_id = ?
    SQL
    return nil unless questions.length > 0
    questions.map {|question| Questions.new(question)}
  end

  def self.most_liked_questions(n)
    questions = QuestionsDB.instance.execute(<<-SQL, n)
      SELECT questions.*
      FROM questions
      JOIN question_likes ON question_likes.question_id = questions.id
      GROUP BY question_likes.question_id
      ORDER BY COUNT(question_likes.user_id) DESC
      LIMIT ?
    SQL
    return nil if questions.empty?
    questions.map {|question| Questions.new(question)}
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end
