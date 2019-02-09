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

require "rails_helper"

RSpec.describe Membership, type: :model do
  subject(:model) { create(:membership, :adult, :with_order_for_purchase) }

  it { is_expected.to be_valid }

  describe "#active_purchases" do
    it "can access purchases directly" do
      expect(model.purchases.count).to be(1)
    end

    it "doesn't list purchases that become inactive" do
      model.orders.update_all(active_to: 1.minute.ago)
      expect(model.purchases.count).to be(0)
    end
  end

  describe "#active_at" do
    let(:membership_available_at) { 1.month.ago }
    let(:membership_inactive_from) { membership_available_at + 1.week }
    let!(:our_membership) { create(:membership, :adult, active_from: membership_available_at, active_to: membership_inactive_from) }

    subject(:scope) { Membership.active_at(time) }

    context "just before membership is available" do
      let(:time) { membership_available_at - 1.second }
      it { is_expected.to_not include(our_membership) }
    end

    context "as the membership becomes available" do
      let(:time) { membership_available_at }
      it { is_expected.to include(our_membership) }
    end

    context "just before membership becomes inactive" do
      let(:time) { membership_inactive_from - 1.second }
      it { is_expected.to include(our_membership) }
    end

    context "as the membership becomes inactive" do
      let(:time) { membership_inactive_from }
      it { is_expected.to_not include(our_membership) }
    end
  end

  describe "#to_s" do
    subject(:to_s) { create(:membership, :kid_in_tow).to_s }
    it { is_expected.to eq "Kid in tow" }
  end
end
