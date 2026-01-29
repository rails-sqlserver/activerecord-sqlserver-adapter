module MiniTestSpecRails
  module SharedTestCaseBehavior
    extend ActiveSupport::Concern

    included do
      before           { setup_dummy_schema }
      let(:app)        { Dummy::Application }
      let(:user_ken)   { User.create! email: 'ken@metaskills.net' }
      let(:user_post)  { Post.create! title: 'Test Title', body: 'Test body. Test body.', user: user_ken }
    end

    private

    def setup_dummy_schema
      ActiveRecord::Base.class_eval do
        connection.instance_eval do
          create_table :users, force: true do |t|
            t.string :email
          end
          create_table :posts, force: true do |t|
            t.string  :title, :body
            t.integer :user_id
          end
        end
      end
    end
  end
end
