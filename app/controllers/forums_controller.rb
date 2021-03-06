class ForumsController < ApplicationController
  before_filter :store_location, :only => [:index, :show]
  before_filter :find_category
  
  # Shows all root forums.
  # Limits this selection to forums the current user has access to.
  # Also gathers stats for the Compulsory Stat Box.
  def index
     if @category
      @forums = @category.forums
    else
      @categories = Category.without_parent.viewable_to(current_user)
      @forums = Forum.without_category.viewable_to(current_user)
    end
    @lusers = User.recent.map { |u| u.to_s }.to_sentence
    @users = User.count
    @posts = Post.count
    @topics = Topic.count
    @ppt = @posts > 0 ? @posts / @topics : 0
    respond_to do |format|
      format.html
      format.xml { render :xml => @forums }
    end
  end
  
  # Shows a forum.
  # Checks first if the current user can see it.
  def show
    @forum = Forum.find(params[:id], :include => [{ :topics => :posts }, :moderations])
    if !@forum.viewable?(current_user)
      flash[:notice] = t(:forum_permission_denied)
      redirect_to forums_path
    else
      @topics = @forum.topics.sorted.paginate :page => params[:page], :per_page => 30, :order => "sticky DESC"
      @forums = @forum.children
      @all_forums = Forum.all(:select => "id, title", :order => "title ASC") - [@forum] if is_moderator?
      @moderated_topics_count = @forum.moderations.topics.for_user(current_user).count
    end
  end
  
  private
  
    def find_category
      @category = Category.find(params[:category_id]) unless params[:category_id].blank?
    end
  
end
