# frozen_string_literal: true

# Copyright 2019 Matthew B. Gray
# Copyright 2019 Steven C Hartley
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

class UserTokensController < ApplicationController
  def new
    redirect_to root_path if signed_in?
    @token = UserToken.new
  end

  def show
    lookup_user_query = Token::LookupOrCreateUser.new(token: params[:id], secret: secret)
    user = lookup_user_query.call
    redirect_path = nil
    if user.present?
      sign_in user
      flash[:notice] = "Logged in as #{user.email}"
      redirect_path = lookup_user_query.path
    else
      error_message = lookup_user_query.errors.to_sentence.humanize
      flash[:error] = "#{error_message}. Please send another link, or email us at #{$member_services_email}"
    end
    redirect_to redirect_path || root_path
  end

  def create
    target_email = params[:email]&.strip
    new_user = User.find_or_initialize_by(email: target_email&.downcase)

    if !new_user.valid? # ...invalid user
      flash[:error] = new_user.errors.full_messages.to_sentence
      redirect_to referrer_path
      return
    elsif !new_user.persisted? # ...valid and never been seen before
      new_user.save!
      sign_in(new_user)
      flash[:notice] = %{
        Welcome #{target_email}!
        Because this is the first time we've seen you, you're automatically signed in.
        In the future, you'll have to check your email.
      }
      redirect_to referrer_path
      return
    end

    send_link_command = Token::SendLink.new(email: target_email, secret: secret, path: referrer_path)
    if send_link_command.call
      flash[:notice] = "Email sent, please check #{target_email} for your login link"
      flash[:notice] += " (http://localhost:1080)" if Rails.env.development?
    else
      flash[:error] = send_link_command.errors.to_sentence
    end
    redirect_to referrer_path
  end

  def kansa_login_link
    sign_out(current_user) if signed_in?
    flash[:error] = "That login link has expired. Please send another link, or email us at #{$member_services_email}"
    redirect_to root_path
  end

  def logout
    if signed_in?
      flash[:notice] = "Signed out #{current_user.email}"
      sign_out(current_user)
    end
    redirect_to root_path
  end

  private

  # Check README.md if this fails for you
  def secret
    ENV["JWT_SECRET"]
  end

  def referrer_path
    if session[:return_path].present?
      return session[:return_path]
    end

    if !request.referrer.present?
      return "/"
    end

    uri = URI(request.referrer)
    if uri.query.present?
      "#{uri.path}?#{uri.query}"
    end

    uri.path
  end
end
