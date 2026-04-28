# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Whooks.Repo.insert!(%Whooks.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
require Logger

Logger.info("Seeding .env user.")

root_email = System.get_env("ROOT_EMAIL")
root_password = System.get_env("ROOT_PASSWORD")

Logger.info("Root email: #{root_email}")
Logger.info("Root password: #{root_password}")

if root_email && root_password do
  %Whooks.Auth.User{}
  |> Whooks.Auth.User.create_changeset(%{
    email: root_email,
    password: root_password,
    role: "root"
  })
  |> Whooks.Repo.insert!(on_conflict: :nothing)
end
