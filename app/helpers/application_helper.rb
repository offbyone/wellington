# frozen_string_literal: true

# Copyright 2019 Matthew B. Gray
# Copyright 2019 AJ Esler
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

module ApplicationHelper
  DEFUALT_NAV_CLASSES = %w(navbar navbar-dark shadow-sm).freeze

  # The root page has an expanded menu
  def navigation_classes
    if request.path == root_path
      DEFUALT_NAV_CLASSES
    else
      DEFUALT_NAV_CLASSES + %w(bg-dark)
    end.join(" ")
  end

  # These match i18n values set in config/locales
  # see Membership#rights
  def membership_right_description(membership_right, reservation)
    description = I18n.t(:description, scope: membership_right)
    tooltip = I18n.t(:layman, scope: membership_right)
    %{
      #{link_if_open(description, membership_right, reservation)}
      #{information_bubble(tooltip)}
    }
  end

  def link_if_open(description, membership_right, reservation)
    if membership_right == "rights.hugo" && $nomination_opens_at < Time.now
      link_to description, reservation_nominations_path(reservation)
    else
      description
    end
  end

  def information_bubble(tooltip_text)
    octicon("info",
      "height" => "15px",
      "aria-label" => "More information",
      "data-toggle" => "tooltip",
      "data-html" => "true",
      "data-placement" => "right",
      "title" => tooltip_text,
    )
  end

  def fuzzy_time(as_at)
    content_tag(
      :span,
      fuzzy_time_in_words(as_at),
      title: as_at&.iso8601 || "Time not set",
    )
  end

  def fuzzy_time_in_words(as_at)
    if as_at.nil?
      "open ended"
    elsif as_at < Time.now
      "#{time_ago_in_words(as_at)} ago"
    else
      "#{time_ago_in_words(as_at)} from now"
    end
  end

  def kiosk?
    @kiosk.present?
  end

  def nomination_text_colour(count_complete)
    case count_complete
    when 0
      "text-primary"
    when Nomination::VOTES_PER_CATEGORY
      "text-dark"
    else
      "text-dark"
    end
  end

  def nomination_accordian_state(category)
    if @category == category
      "collapse show"
    else
      "collapse"
    end
  end
end
