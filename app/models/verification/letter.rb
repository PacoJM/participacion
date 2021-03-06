class Verification::Letter
  include ActiveModel::Model

  attr_accessor :user, :verification_code

  validates :user, presence: true

  def save
    valid? &&
    letter_requested!
  end

  def letter_requested!
    user.update(letter_requested_at: Time.now, letter_verification_code: generate_verification_code)
  end

  def verified?
    validate_letter_sent
    validate_correct_code
    errors.blank?
  end

  def validate_letter_sent
    errors.add(:verification_code, I18n.t('verification.letter.errors.letter_not_sent')) unless
    user.letter_sent_at.present?
  end

  def validate_correct_code
    errors.add(:verification_code, I18n.t('verification.letter.errors.incorect_code')) unless
    user.letter_verification_code == verification_code
  end

  def increase_letter_verification_tries
    user.update(letter_verification_tries: user.letter_verification_tries += 1)
  end

  private

    def generate_verification_code
      rand.to_s[2..7]
    end

end
