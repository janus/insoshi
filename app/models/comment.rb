# == Schema Information
# Schema version: 15
#
# Table name: comments
#
#  id               :integer(11)     not null, primary key
#  commenter_id     :integer(11)     
#  commentable_id   :integer(11)     
#  commentable_type :string(255)     default(""), not null
#  body             :text            
#  created_at       :datetime        
#  updated_at       :datetime        
#

class Comment < ActiveRecord::Base
  include ActivityLogger
  
  belongs_to :commentable, :polymorphic => true
  belongs_to :commenter, :class_name => "Person",
                         :foreign_key => "commenter_id"
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy

  validates_presence_of :body, :commenter
  validates_length_of :body, :maximum => MAX_TEXT_LENGTH
  
  after_create :log_activity
  
  private
    
    # Return the person for the thing commented on.
    # For example, for blog post comments it's the blog's person
    # For wall comments, it's the person himself.
    def commented_person
      case commentable.class.to_s
      when "Person"
        commentable
      when "BlogPost"
        commentable.blog.person
      end
    end
  
    def log_activity
      activity = Activity.create!(:item => self, :person => commenter)
      add_activities(:activity => activity, :person => commenter)
      unless commented_person.nil?
        add_activities(:activity => activity, :person => commented_person)
      end
    end
end
