# frozen_string_literal: true

HealthMonitorRfc::Engine.routes.draw do
  controller :health do
    get :health
  end
end
