require 'csv'

class EntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entry, only: %i[ show edit update destroy ]

  # GET /entries or /entries.json
  def index
    @entries = Entry.where(user: current_user).by_year(Date.today.year).by_month(Date.today.month).includes(:category)
    @years = Entry.where(user: current_user).order(:date).pluck(:date).uniq { |d| d.year }.map(&:year)
  end

  # POST /filtered_entries
  def filtered_index
    @entries = Entry.where(user: current_user)
                    .by_year(params['year'])
                    .by_month(params['month'])
                    .by_income(params['income'])

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(:entries, partial: "entries", locals: { entries: @entries }) }
    end
  end

  # GET /entries/1 or /entries/1.json
  def show
  end

  # GET /entries/new
  def new
    @entry = Entry.new
    @entry.build_tag
    @categories = current_user.categories.where(year: current_user.year_view)
  end

  # GET /entries/1/edit
  def edit
    @categories = current_user.categories.where(year: current_user.year_view)
    @entry.build_tag unless @entry.tag
  end

  # POST /entries
  def create
    @entry = Entry.new(entry_params)
    @entry.user = current_user

    if @entry.save
      redirect_to new_entry_url, notice: "Entry was successfully created."
    else
      @categories = current_user.categories.where(year: current_user.year_view)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /entries/1
  def update
    if @entry.update(entry_params)
      redirect_to entry_url(@entry), notice: "Entry was successfully updated."
    else
      @categories = current_user.categories.where(year: current_user.year_view)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /entries/1
  def destroy
    @entry.destroy
    redirect_to entries_url, notice: "Entry was successfully destroyed."
  end

  # GET /entries/export
  def export
    @entries = Entry.where(user: current_user)
    respond_to do |format|
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=entries.csv"
        render 'export'
      end
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entry
      @entry = Entry.where(user: current_user).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to entries_url, notice: "Entry not found."
    end

    # Only allow a list of trusted parameters through.
    def entry_params
      params.require(:entry).permit(:date, :amount, :notes, :category_name, :income, :untracked, :user_id, :category_id, tag_attributes: [:id, :name, :_destroy])
    end
end
