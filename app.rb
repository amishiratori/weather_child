require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'RMagick'
require 'open-uri'

enable :sessions

before do
  Dotenv.load
  Cloudinary.config do |config|
    config.cloud_name = ENV['CLOUD_NAME']
    config.api_key    = ENV['CLOUDINARY_API_KEY']
    config.api_secret = ENV['CLOUDINARY_API_SECRET']
  end
end

get '/' do
  erb  :index
end

post '/new' do
  text = params[:text]
  x = 1
  y = 1

  path = params[:file][:tempfile].path
  original = Magick::Image.read(path).first
  unless original.columns > original.rows
    image = original.resize_to_fill(810, 600)
  else
    image = original.resize_to_fill(1080, 810)
  end
  image = image.modulate(1.5,1.5)
  image = image.matte_floodfill(10, 10)

  background = Magick::Image.read('public/images/sky.png').first
  background = background.dissolve(image,0.6, 1.0,Magick::CenterGravity, 0, 0)

  annotate = Magick::Draw.new
    font = 'public/fonts/A-OTF-A1.otf'
    text = "#{text}の子"
    annotate.annotate(background, 0, 0, 0, 150, text) do
      self.font      = font
      self.fill      = 'white'
      self.stroke    = 'transparent'
      self.pointsize = 80
      self.interline_spacing = 2
      self.gravity   = Magick::CenterGravity
    end

  background.write(path + ".png")

  upload = Cloudinary::Uploader.upload(path + ".png")
  img_url = upload['url']
  session[:url] = img_url

  redirect '/'
end
