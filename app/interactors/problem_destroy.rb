class ProblemDestroy

  attr_reader :problem

  def initialize(problem)
    @problem = problem
  end

  def execute
    delete_errs
    delete_comments
    problem.delete
    # Mongoid doesn't remove entries deleted with
    # collection.remove(:field => { '$in' => array }) queries
    # So, to be safe, we should clear the identity map
    Mongoid::IdentityMap.clear
  end

  ##
  # Destroy all problem pass in args
  #
  # @params [ Array[Problem] ] problems the list of problem need to be delete
  #   can be a single Problem
  # @return [ Integer ]
  #   the number of problem destroy
  #
  def self.execute(problems)
    Array(problems).each{ |problem|
      ProblemDestroy.new(problem).execute
    }.count
  end

  private

  def errs_id
    problem.errs.only(:id).map(&:id)
  end

  def comments_id
    problem.comments.only(:id).map(&:id)
  end

  def delete_errs
    Notice.collection.remove(:err_id => { '$in' => errs_id })
    Err.collection.remove(:_id => { '$in' => errs_id })
  end

  def delete_comments
    Comment.collection.remove(:_id => { '$in' => comments_id })
  end

end
