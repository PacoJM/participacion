module CommentableActions
  extend ActiveSupport::Concern

  def index
    @resources = @search_terms.present? ? resource_model.search(@search_terms) : resource_model.all
    @resources = @resources.tagged_with(@tag_filter) if @tag_filter
    @resources = @resources.page(params[:page]).for_render.send("sort_by_#{@current_order}")
    @tag_cloud = tag_cloud

    set_resource_votes(@resources)
    set_resources_instance
  end

  def show
    set_resource_votes(resource)
    @commentable = resource
    @root_comments = resource.comments.roots.recent.page(params[:page]).per(10).for_render
    @comments = @root_comments.inject([]){|all, root| all + Comment.descendants_of(root).for_render}
    @all_visible_comments = @root_comments + @comments

    set_comment_flags(@all_visible_comments)
    set_resource_instance
  end

  def new
    @resource = resource_model.new
    set_resource_instance
    load_featured_tags
  end

  def create
    @resource = resource_model.new(strong_params)
    @resource.author = current_user

    if @resource.save_with_captcha
      track_event
      redirect_to @resource, notice: t('flash.actions.create.notice', resource_name: "#{resource_name.capitalize}")
    else
      load_featured_tags
      set_resource_instance
      render :new
    end
  end

  def edit
    load_featured_tags
  end

  def update
    resource.assign_attributes(strong_params)
    if resource.save_with_captcha
      redirect_to resource, notice: t('flash.actions.update.notice', resource_name: "#{resource_name.capitalize}")
    else
      load_featured_tags
      set_resource_instance
      render :edit
    end
  end

  private
    def resource
      @resource ||= instance_variable_get("@#{resource_name}")
    end

    def resource_name
      @resource_name ||= resource_model.to_s.downcase
    end

    def set_resource_instance
      instance_variable_set("@#{resource_name}", @resource)
    end

    def set_resources_instance
      instance_variable_set("@#{resource_name.pluralize}", @resources)
    end

    def set_resource_votes(instance)
      send("set_#{resource_name}_votes", instance)
    end

    def strong_params
      send("#{resource_name}_params")
    end

    def track_event
      ahoy.track "#{resource_name}_created".to_sym, "#{resource_name}_id": resource.id
    end

    def tag_cloud
      resource_model.tag_counts.order("#{resource_name.pluralize}_count": :desc, name: :asc).limit(20)
    end

    def load_featured_tags
      @featured_tags = ActsAsTaggableOn::Tag.where(featured: true)
    end

    def parse_tag_filter
      if params[:tag].present?
        @tag_filter = params[:tag] if ActsAsTaggableOn::Tag.named(params[:tag]).exists?
      end
    end

    def parse_search_terms
      @search_terms = params[:search] if params[:search].present?
    end
end