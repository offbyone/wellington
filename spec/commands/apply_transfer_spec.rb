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

RSpec.describe ApplyTransfer do
  let(:seller) { create(:user) }
  let(:buyer) { create(:user) }
  let(:support) { create(:support) }
  let(:reservation) { create(:reservation) }

  before { Claim.create!(user: seller, reservation: reservation, active_from: reservation.created_at) }

  subject(:command) { described_class.new(reservation, from: seller, to: buyer, audit_by: support.email) }
  let(:soonish) { 1.minute.from_now } # ApplyTransfer is relying on Time.now which is a very small time slice

  it "doesn't change the number of memberships overall" do
    expect { command.call }.to_not change { Reservation.count }
  end

  it "adds claim to buyer" do
    expect { command.call }.to change { buyer.claims.active_at(soonish).count }.by(1)
  end

  it "deactivates claim on seller" do
    expect { command.call }.to change { seller.claims.active_at(soonish).count }.by(-1)
  end

  it "leaves notes on the users" do
    expect { command.call }.to change { Note.count }.by(2)
    expect(seller.notes.last.content).to include(support.email)
    expect(buyer.notes.last.content).to include(support.email)
  end

  context "when there's transactions close together" do
    let(:this_instant) { Time.now }
    before { expect(Time).to receive(:now).at_least(1).times.and_return(this_instant) }

    it "doesn't let you transfer twice" do
      expect(command.call).to be_truthy
      expect(command.call).to be_falsey
      expect(command.errors).to include(/claim/i)
      expect(Claim.count).to be 2
    end
  end

  context "when reservation is pay by installment" do
    let(:reservation) { create(:reservation, :pay_as_you_go) }

    it "doesn't let you transfer" do
      expect(command.call).to be_falsey
      expect(command.errors).to include(/reservation/i)
    end
  end
end
