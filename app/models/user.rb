class User < ApplicationRecord
	before_save { self.email.downcase! }
	validates :name, presence: true, length: { maximum: 50 }
	validates :email, presence: true, length: { maximum: 255 },
                    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
                    uniqueness: { case_sensitive: false }
	has_secure_password
	
	has_many :microposts
	
	has_many :relationships
  has_many :followings, through: :relationships, source: :follow
  has_many :reverses_of_relationship, class_name: 'Relationship', foreign_key: 'follow_id'
  has_many :followers, through: :reverses_of_relationship, source: :user
  
  def follow(other_user)
    unless self == other_user
      self.relationships.find_or_create_by(follow_id: other_user.id)
    end
  end

  def unfollow(other_user)
    relationship = self.relationships.find_by(follow_id: other_user.id)
    relationship.destroy if relationship
  end

  def following?(other_user)
    self.followings.include?(other_user)
  end
  
  def feed_microposts
    Micropost.where(user_id: self.following_ids + [self.id])
  end 
  
  has_many :post_relationships, class_name: 'PostRelationship', foreign_key: 'user_id', dependent: :destroy
  has_many :favings, through: :post_relationships, source: :fav
  
  def fav(fav_post)
    self.post_relationships.find_or_create_by(fav_id: fav_post.id)
  end

  def unfav(fav_post)
    post_relationship = self.post_relationships.find_by(fav_id: fav_post.id)
    post_relationship.destroy if post_relationship
  end

  def faving?(fav_post)
    self.favings.include?(fav_post)
  end
  
  def fav_microposts
    Micropost.where(id: self.faving_ids)
  end
end
