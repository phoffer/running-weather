# encoding: utf-8
require 'json'
require 'time'
require 'haversine'
require 'garmin_connect'
require 'mongoid'

Mongoid.load!(File.dirname(__FILE__) + '/mongoid.yaml')

require_relative 'wunderground'
require_relative 'garmin_ext'
require_relative 'mongoid'
