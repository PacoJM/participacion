require 'rails_helper'

feature 'Verify Letter' do

  scenario 'Verify' do
    user = create(:user, residence_verified_at: Time.now,
                         confirmed_phone:       "611111111",
                         letter_sent_at:        1.day.ago)

    login_as(user)
    visit new_letter_path

    click_button "Send me a letter with the code"

    expect(page).to have_content "Thank you for requesting a maximum security code in a few days we will send it to the address on your census data."

    user.reload
    fill_in "letter_verification_code", with: user.letter_verification_code
    click_button "Send"

    expect(page).to have_content "Correct code. Your account is verified"
  end

  scenario 'Go to office instead of send letter' do
    user = create(:user, residence_verified_at: Time.now,
                         confirmed_phone:       "611111111",
                         letter_sent_at:        1.day.ago)

    login_as(user)
    visit new_letter_path

    expect(page).to have_link "See Office of Citizen", href: "http://www.madrid.es/portales/munimadrid/es/Inicio/El-Ayuntamiento/Atencion-al-ciudadano/Oficinas-de-Atencion-al-Ciudadano?vgnextfmt=default&vgnextchannel=5b99cde2e09a4310VgnVCM1000000b205a0aRCRD"
  end

  scenario 'Errors on verification code' do
    user = create(:user, residence_verified_at: Time.now,
                         confirmed_phone:       "611111111",
                         letter_sent_at:        1.day.ago)

    login_as(user)
    visit new_letter_path

    click_button "Send me a letter with the code"
    expect(page).to have_content "Thank you for requesting a maximum security code in a few days we will send it to the address on your census data."

    fill_in "letter_verification_code", with: "1"
    click_button "Send"

    expect(page).to have_content "Incorrect confirmation code"
  end

  scenario "Deny access unless verified residence" do
    user = create(:user)

    login_as(user)
    visit new_letter_path

    expect(page).to have_content 'You have not yet confirmed your residence'
    expect(current_path).to eq(new_residence_path)
  end

  scenario "Deny access unless verified phone/email" do
    user = create(:user, residence_verified_at: Time.now)

    login_as(user)
    visit new_letter_path

    expect(page).to have_content 'You have not yet enter the confirmation code'
    expect(current_path).to eq(new_sms_path)
  end

  scenario '6 tries allowed' do
    user = create(:user, residence_verified_at: Time.now, confirmed_phone: "611111111")
    login_as(user)

    visit new_letter_path
    click_button 'Send me a letter with the code'

    6.times do
      fill_in 'letter_verification_code', with: "999999"
      click_button 'Send'
    end

    expect(page).to have_content "You have reached the maximum number of verification tries. Please try again later."
    expect(current_path).to eq(account_path)

    visit new_letter_path
    expect(page).to have_content "You have reached the maximum number of verification tries. Please try again later."
    expect(current_path).to eq(account_path)
  end

end
