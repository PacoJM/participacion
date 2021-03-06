require 'rails_helper'

feature 'Admin::Organizations' do

  background do
    administrator = create(:user)
    create(:administrator, user: administrator)

    login_as(administrator)
  end

  context "Index" do
    scenario "shows info on organizations with hidden users" do
      troll = create(:user, email: "trol@troller.com")
      create(:organization, user: troll, name: "Greentroll")
      org = create(:organization, name: "Human Rights")
      troll.hide

      visit admin_organizations_path

      expect(page).to have_content("Human Rights")
      expect(page).to have_content(org.user.email)
      expect(page).to_not have_content("Greentroll")
      expect(page).to_not have_content("trol@troller.com")
      expect(page).to have_content("There is 1 organization without user or with the user banned")
    end
  end

  context "Search" do

    background do
      @user = create(:user, email: "marley@humanrights.com", phone_number: "6764440002")
      create(:organization, user: @user, name: "Get up, Stand up")
    end

    scenario "returns no results if search term is empty" do
      visit admin_organizations_path
      expect(page).to have_content("Get up, Stand up")

      fill_in "term", with: "      "
      click_button "Search"

      expect(current_path).to eq(search_admin_organizations_path)
      within("#search-results") do
        expect(page).to_not have_content("Get up, Stand up")
      end
    end

    scenario "finds by name" do
      visit search_admin_organizations_path
      expect(page).to_not have_content("Get up, Stand up")

      fill_in "term", with: "Up, sta"
      click_button "Search"

      within("#search-results") do
        expect(page).to have_content("Get up, Stand up")
      end
    end

    scenario "finds by users email" do
      visit search_admin_organizations_path
      expect(page).to_not have_content("Get up, Stand up")

      fill_in "term", with: @user.email
      click_button "Search"

      within("#search-results") do
        expect(page).to have_content("Get up, Stand up")
      end
    end

    scenario "finds by users phone number" do
      visit search_admin_organizations_path
      expect(page).to_not have_content("Get up, Stand up")

      fill_in "term", with: @user.phone_number
      click_button "Search"

      within("#search-results") do
        expect(page).to have_content("Get up, Stand up")
      end
    end
  end

  scenario "Pending organizations have links to verify and reject" do
    organization = create(:organization)

    visit admin_organizations_path
    within("#organization_#{organization.id}") do
      expect(current_path).to eq(admin_organizations_path)
      expect(page).to have_link('Verify')
      expect(page).to have_link('Reject')

      click_on 'Verify'
    end
    expect(current_path).to eq(admin_organizations_path)
    expect(page).to have_content ('Verified')

    expect(organization.reload.verified?).to eq(true)
  end

  scenario "Verified organizations have link to reject" do
    organization = create(:organization, :verified)

    visit admin_organizations_path

    click_on "Verified"

    within("#organization_#{organization.id}") do
      expect(page).to have_content ('Verified')
      expect(page).to_not have_link('Verify')
      expect(page).to have_link('Reject')

      click_on 'Reject'
    end
    expect(current_path).to eq(admin_organizations_path)
    expect(page).to_not have_content (organization.name)

    click_on 'Rejected'
    expect(page).to have_content ('Rejected')
    expect(page).to have_content (organization.name)

    expect(organization.reload.rejected?).to eq(true)
  end

  scenario "Rejected organizations have link to verify" do
    organization = create(:organization, :rejected)

    visit admin_organizations_path
    click_on "Rejected"

    within("#organization_#{organization.id}") do
      expect(page).to have_link('Verify')
      expect(page).to_not have_link('Reject', exact: true)

      click_on 'Verify'
    end
    expect(current_path).to eq(admin_organizations_path)
    expect(page).to_not have_content (organization.name)
    click_on('Verified')

    expect(page).to have_content (organization.name)

    expect(organization.reload.verified?).to eq(true)
  end

  scenario "Current filter is properly highlighted" do
    visit admin_organizations_path
    expect(page).to_not have_link('Pending')
    expect(page).to have_link('All')
    expect(page).to have_link('Verified')
    expect(page).to have_link('Rejected')

    visit admin_organizations_path(filter: 'all')
    expect(page).to_not have_link('All')
    expect(page).to have_link('Pending')
    expect(page).to have_link('Verified')
    expect(page).to have_link('Rejected')

    visit admin_organizations_path(filter: 'pending')
    expect(page).to have_link('All')
    expect(page).to_not have_link('Pending')
    expect(page).to have_link('Verified')
    expect(page).to have_link('Rejected')

    visit admin_organizations_path(filter: 'verified')
    expect(page).to have_link('All')
    expect(page).to have_link('Pending')
    expect(page).to_not have_link('Verified')
    expect(page).to have_link('Rejected')

    visit admin_organizations_path(filter: 'rejected')
    expect(page).to have_link('All')
    expect(page).to have_link('Pending')
    expect(page).to have_link('Verified')
    expect(page).to_not have_link('Rejected')
  end

  scenario "Filtering organizations" do
    create(:organization, name: "Pending Organization")
    create(:organization, :rejected, name: "Rejected Organization")
    create(:organization, :verified, name: "Verified Organization")

    visit admin_organizations_path(filter: 'all')
    expect(page).to have_content('Pending Organization')
    expect(page).to have_content('Rejected Organization')
    expect(page).to have_content('Verified Organization')

    visit admin_organizations_path(filter: 'pending')
    expect(page).to have_content('Pending Organization')
    expect(page).to_not have_content('Rejected Organization')
    expect(page).to_not have_content('Verified Organization')

    visit admin_organizations_path(filter: 'verified')
    expect(page).to_not have_content('Pending Organization')
    expect(page).to_not have_content('Rejected Organization')
    expect(page).to have_content('Verified Organization')

    visit admin_organizations_path(filter: 'rejected')
    expect(page).to_not have_content('Pending Organization')
    expect(page).to have_content('Rejected Organization')
    expect(page).to_not have_content('Verified Organization')
  end

  scenario "Verifying organization links remember the pagination setting and the filter" do
    per_page = Kaminari.config.default_per_page
    (per_page + 2).times { create(:organization) }

    visit admin_organizations_path(filter: 'pending', page: 2)

    click_on('Verify', match: :first)

    expect(current_url).to include('filter=pending')
    expect(current_url).to include('page=2')
  end

end
