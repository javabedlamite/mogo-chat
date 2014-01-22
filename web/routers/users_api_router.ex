defmodule UsersApiRouter do
  use Dynamo.Router
  use Ecto.Query
  import Cheko.RouterUtils

  prepare do
    authorize_user!(conn, ["admin"])
  end


  get "/" do
    users = Repo.all User
    users_attributes = lc user inlist users do
      User.attributes(user, ["id", "first_name", "last_name", "role", "email"])
    end
    json_response([users: users_attributes], conn)
  end


  post "/" do
    {:ok, params} = conn.req_body
    |> JSEX.decode

    user_params = whitelist_params(params["user"], ["first_name", "last_name", "email", "password", "role"])
    user = User.new(user_params)
    |> User.encrypt_password()

    case User.validate(user) do
      [] ->
        saved_user = Repo.create(user)
        json_response [user: User.public_attributes(saved_user)], conn
      errors ->
        json_response [errors: errors], conn, 422
    end
  end


  get "/:user_id" do
    user_id = conn.params["user_id"]
    user = Repo.get User, user_id
    user_attributes = User.attributes(user, ["id", "first_name", "last_name", "role", "email"])
    json_response [user: user_attributes], conn
  end


  put "/:user_id" do
    user_id = conn.params[:user_id]
    {:ok, params} = conn.req_body
    |> JSEX.decode

    user_params = whitelist_params(params["user"], ["first_name", "last_name", "email", "password", "role"])
    user = Repo.get(User, user_id).update(user_params)
    |> User.encrypt_password()

    case User.validate(user) do
      [] ->
        :ok = Repo.update(user)
        json_response [user: User.public_attributes(user)], conn
      errors ->
        json_response [errors: errors], conn, 422
    end
  end


  delete "/:user_id" do
    user_id = conn.params["user_id"]
    current_user_id = get_session(conn, :user_id)
    if current_user_id != user_id do
      user = User.new(id: user_id)
      Repo.delete user
    end
    json_response("", conn)
  end

end