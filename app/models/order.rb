# frozen_string_literal: true

# Copyright 2018 Matthew B. Gray
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

class Order < ApplicationRecord
  include ActiveScopes

  validates :membership, presence: true
  validates :purchase, presence: true, uniqueness: {
    # There can't be other active orders against the same purchase
    conditions: -> { active }
  }

  belongs_to :membership
  belongs_to :purchase
end