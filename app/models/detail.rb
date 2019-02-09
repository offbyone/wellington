# frozen_string_literal: true

# Copyright 2019 Matthew B. Gray
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

class Detail < ApplicationRecord
  # TODO Move this to i18n
  PAPERPUBS_ELECTRONIC = "send_me_email"
  PAPERPUBS_MAIL = "send_me_post"
  PAPERPUBS_BOTH = "send_me_email_and_post"
  PAPERPUBS_NONE = "no_paper_pubs"

  PAPERPUBS_OPTIONS = [
    PAPERPUBS_ELECTRONIC,
    PAPERPUBS_MAIL,
    PAPERPUBS_BOTH,
    PAPERPUBS_NONE
  ].freeze

  PERMITTED_PARAMS = [
    :legal_name,
    :preferred_first_name,
    :preferred_last_name,
    :badge_title,
    :badge_subtitle,
    :share_with_future_worldcons,
    :show_in_listings,
    :address_line_1,
    :address_line_2,
    :city,
    :province,
    :postal,
    :country,
    :publication_format,
    :interest_volunteering,
    :interest_accessibility_services,
    :interest_being_on_program,
    :interest_dealers,
    :interest_selling_at_art_show,
    :interest_exhibiting,
    :interest_performing
  ].freeze

  belongs_to :claim

  attr_reader :for_import

  validates :address_line_1, presence: true, unless: :for_import
  validates :claim, presence: true
  validates :country, presence: true, unless: :for_import
  validates :legal_name, presence: true
  validates :publication_format, inclusion: { in: PAPERPUBS_OPTIONS }

  def as_import
    @for_import = true
    self
  end

  # This maps loosely to what we promise on the form, we use preferred name but fall back to legal name
  def to_s
    if preferred_first_name.present? || preferred_last_name.present?
      "#{preferred_first_name} #{preferred_last_name}".strip
    else
      "#{legal_name}"
    end
  end
end