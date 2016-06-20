class Change < ActiveRecord::Base
  belongs_to :before, polymorphic: true
  validates  :before, presence: true

  belongs_to :after, polymorphic: true
  validates  :after, presence: true

  validate :correct_ordering
  def correct_ordering
    # delegate order checking to the attached models
    if before.created_at > after.created_at
      errors.add(:after, "'after' must be created_at after 'before'")
    end
  end

  # TODO: service object should manage creating changes and notifications, after_create for now
  after_create :send_notifications
  def send_notifications
    subscriptions = Subscription.where(watching: self.after.parent)
    subscriptions.all.map do |subscription|
      subscription.send_notification(self)
    end
  end

  def self.check
    Page.all.each do |page|
      # if we have multiple snapshots, only notify for the change between the last two

      current = page.page_snapshots.order('created_at DESC').first

      if current.previous.nil?
        next
      end

      Change.where(
        before: current.previous,
        after:  current
      ).first_or_create
    end
  end

end
