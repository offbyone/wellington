# frozen_string_literal: true

# Copyright 2020 Matthew B. Gray
# Copyright 2020 Victoria Garcia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class NominationMailer < ApplicationMailer
  include ApplicationHelper

  default from: $member_services_email

  def nomination_ballot(reservation)
    binding.pry
    @detail = reservation.active_claim.contact
    nominated_categories = Category.joins(nominations: :reservation).where(reservations: {id: reservation})

    builder = MemberNominationsByCategory.new(
      reservation: reservation,
      categories: nominated_categories.order(:order, :id),
    )
    builder.from_reservation
    @nominations_by_category = builder.nominations_by_category

    mail(
      subject: "Your #{worldcon_year} Hugo and #{retro_hugo_year} Retro Hugo Nominations Ballot",
      to: reservation.user.email,
      from: "Hugo Awards #{worldcon_year} <#{email_hugo_help}>"
    )
  end

  def nominations_open_dublin(user:)
    @user = user
    @reservations = user.reservations.joins(:membership).where(memberships: {name: :dublin_2019})

    @account_numbers = account_numbers_from(@reservations)
    if @account_numbers.count == 1
      subject = "CoNZealand: Hugo Nominations are now open for account #{@account_numbers.first}"
    else
      subject = "CoNZealand: Hugo Nominations are now open for accounts #{@account_numbers.to_sentence}"
    end

    mail(to: user.email, from: "hugohelp@conzealand.nz", subject: subject)
  end

  def nominations_open_conzealand(user:)
    @user = user
    @reservations = user.reservations.joins(:membership).merge(Membership.can_nominate)

    account_numbers = account_numbers_from(@reservations)
    if account_numbers.count == 1
      subject = "CoNZealand: Hugo Nominations are now open for member #{account_numbers.first}"
    else
      subject = "CoNZealand: Hugo Nominations are now open for members #{account_numbers.to_sentence}"
    end

    mail(to: user.email, from: "hugohelp@conzealand.nz", subject: subject)
  end

  def nominations_reminder_2_weeks_left_conzealand(email:)
    user = User.find_by!(email: email)
    reservations_that_can_nominate = user.reservations.joins(:membership).merge(Membership.can_nominate)

    if reservations_that_can_nominate.none?
      return
    end

    account_numbers = account_numbers_from(reservations_that_can_nominate)
    if account_numbers.count == 1
      subject = "2 weeks to go! Hugo Award Nominating Reminder for member #{account_numbers.first}"
    else
      subject = "2 weeks to go! Hugo Award Nominating Reminder for members #{account_numbers.to_sentence}"
    end

    @details = Detail.where(claim_id: user.active_claims)

    mail(to: user.email, from: "hugohelp@conzealand.nz", subject: subject)
  end

  def nominations_reminder_2_weeks_left_dublin(email:)
    user = User.find_by!(email: email)
    reservations_that_can_nominate = user.reservations.joins(:membership).merge(Membership.can_nominate)

    if reservations_that_can_nominate.none?
      return
    end

    account_numbers = account_numbers_from(reservations_that_can_nominate)
    if account_numbers.count == 1
      subject = "2 weeks to go! Hugo Award Nominating Reminder for account #{account_numbers.first}"
    else
      subject = "2 weeks to go! Hugo Award Nominating Reminder for accounts #{account_numbers.to_sentence}"
    end

    @details = Detail.where(claim_id: user.active_claims)

    mail(to: user.email, from: "hugohelp@conzealand.nz", subject: subject)
  end

  # Unlike the other templates the only difference in this is the subject line, hence a single mailer
  def nominations_reminder_3_days_left(email:)
    user = User.find_by!(email: email)

    if user.reservations.none?
      return
    end

    account_numbers = account_numbers_from(user.reservations)
    conzealand = conzealand_memberships.where(reservations: {id: user.reservations}).any?

    if account_numbers.count == 1 && conzealand
      subject = "Hugo Nominations Close in 3 Days! for member #{account_numbers.first}"
    elsif conzealand
      subject = "Hugo Nominations Close in 3 Days! for members #{account_numbers.to_sentence}"
    elsif account_numbers.count == 1
      subject = "Hugo Nominations Close in 3 Days! for account #{account_numbers.first}"
    else
      subject = "Hugo Nominations Close in 3 Days! for accounts #{account_numbers.to_sentence}"
    end

    @details = Detail.where(claim_id: user.active_claims)

    mail(to: user.email, from: "#{hugo_help_email}", subject: subject)
  end

  private

  # Given reservations, gets membership numbers and puts a pound in front of each
  def account_numbers_from(reservations)
    reservations.pluck(:membership_number).map { |n| "##{n}" }
  end

  def conzealand_memberships
    Membership.can_nominate.where.not(name: :dublin).joins(:reservations)
  end

  def chicago_memberships
    # TODO: Write this query
  end
end
