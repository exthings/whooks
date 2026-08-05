defmodule Whooks.OrganizationsTest do
  use Whooks.DataCase

  alias Whooks.Organizations

  describe "organizations" do
    alias Whooks.Organizations.Organization

    import Whooks.OrganizationsFixtures

    @invalid_attrs %{name: nil}

    test "list/0 returns all organizations" do
      organization = organization_fixture()
      assert Organizations.list() == [organization]
    end

    test "get!/1 returns the organization with given id" do
      organization = organization_fixture()
      assert Organizations.get!(organization.id) == organization
    end

    test "create/1 with valid data creates a organization" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Organization{} = organization} = Organizations.create(valid_attrs)
      assert organization.name == "some name"
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organizations.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the organization" do
      organization = organization_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Organization{} = organization} = Organizations.update(organization, update_attrs)
      assert organization.name == "some updated name"
    end

    test "update/2 with invalid data returns error changeset" do
      organization = organization_fixture()
      assert {:error, %Ecto.Changeset{}} = Organizations.update(organization, @invalid_attrs)
      assert organization == Organizations.get!(organization.id)
    end

    test "delete/1 deletes the organization" do
      organization = organization_fixture()
      assert {:ok, %Organization{}} = Organizations.delete(organization)
      assert_raise Ecto.NoResultsError, fn -> Organizations.get!(organization.id) end
    end

    test "change/1 returns a organization changeset" do
      organization = organization_fixture()
      assert %Ecto.Changeset{} = Organizations.change(organization)
    end
  end
end
