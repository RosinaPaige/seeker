require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe DocumentsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Document. As you add validations to Document, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    {
      url: 'http://www.coe.int/t/dg4/education/minlang/Report/EvaluationReports/UKECRML1_en.pdf',
      country_id: 25,
      year: 2004,
      cycle: 1,
      document_type: 1
    }
  }

  let(:invalid_attributes) {
    {
      url: 'http://www.coe.int/t/dg4/education/minlang/Report/EvaluationReports/UKECRML1_en.pdf',
      country_id: 'inv',
      year: 'inv',
      cycle: 1,
      document_type: 1
    }
  }

  describe 'GET #index' do
    it 'redirects non logged-in users to login page' do
      login_with nil
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'lets logged-in users to see all documents' do
      login_with create(:user)
      get :index
      expect(response).to render_template(:index)
    end

    it 'assigns all documents as @documents' do
      login_with create(:user)
      document = create(:document, :finished_parsing)
      get :index
      expect(assigns['grouped_documents'].values.first).to eq([document])
    end
  end

  describe 'GET #new' do
    it 'redirects non logged-in users to login page' do
      login_with nil
      get :new
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'assigns a new document as @document' do
      login_with create(:user)
      get :new
      expect(assigns(:document)).to be_a_new(Document)
    end
  end

  describe "POST #create" do
    it 'redirects non logged-in users to login page' do
      login_with nil
      post :create
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'with valid params' do
      before :each do
        login_with create(:user)
      end

      it 'creates a new Document' do
        expect {
          post :create, document: valid_attributes
        }.to change(Document, :count).by(1)
      end

      it 'assigns a newly created document as @document' do
        post :create, document: valid_attributes
        expect(assigns(:document)).to be_a(Document)
        expect(assigns(:document)).to be_persisted
      end

      it 'redirects to the created document' do
        post :create, document: valid_attributes
        expect(response).to redirect_to(Document.last)
      end
    end

    context 'with invalid params' do
      before :each do
        login_with create(:user)
      end

      it 'assigns a newly created but unsaved document as @document' do
        post :create, document: invalid_attributes
        expect(assigns(:document)).to be_a_new(Document)
      end

      it "re-renders the 'new' template" do
        post :create, document: invalid_attributes
        expect(response).to render_template("new")
      end
    end
  end

  describe "DELETE #destroy" do
    it 'redirects non logged-in users to login page' do
      login_with nil
      document = Document.create! valid_attributes
      delete :destroy, id: document.to_param
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'destroys the requested document' do
      login_with create(:user)
      document = Document.create! valid_attributes
      expect {
        delete :destroy, id: document.to_param
      }.to change(Document, :count).by(-1)
    end

    it 'redirects to the documents list' do
      login_with create(:user)
      document = Document.create! valid_attributes
      delete :destroy, id: document.to_param
      expect(response).to redirect_to(documents_url)
    end
  end

  describe 'edit section separation' do
    context 'non logged-in users' do
      before :each do
        login_with nil
      end

      it 'redirects non logged-in users to login page' do
        document = Document.create! valid_attributes
        get :edit_section_separation, id: document.to_param
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects non logged-in users to login page' do
        document = Document.create! valid_attributes
        post :update_section_separation, id: document.to_param
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'logged-in users' do
      before :each do
        login_with create(:user)
      end

      it 'allows logged-in users to edit section separation' do
        document = create(:document, :finished_parsing)
        get :edit_section_separation, id: document.id
        expect(response).to render_template(:edit_section_separation)
      end
    end
  end

end