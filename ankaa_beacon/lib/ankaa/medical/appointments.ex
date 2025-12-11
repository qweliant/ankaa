defmodule Ankaa.Medical.Appointment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "appointments" do
    field :title, :string
    field :provider_name, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :is_all_day, :boolean, default: false
    field :location_name, :string
    field :address, :string
    field :notes, :string

    belongs_to :patient, Ankaa.Patients.Patient

    timestamps(type: :utc_datetime)
  end

  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [:title, :provider_name, :start_time, :end_time, :is_all_day, :location_name, :address, :notes, :patient_id])
    |> validate_required([:title, :start_time, :patient_id])
  end
end
