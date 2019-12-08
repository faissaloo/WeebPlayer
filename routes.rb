# This file is part of WeebPlayer.
#
# WeebPlayer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# WeebPlayer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with WeebPlayer.  If not, see <https://www.gnu.org/licenses/>.

require_relative './music_db'

db = MusicDB.new(music_path: ENV['HOME'] + '/Music')
db.load_async

def get_shuffle_url(current_url:)
	"#{current_url.sub(/(?:\/|\/shuffle)$/, '')}/shuffle"
end

get '/' do
	load_status = db.load_status

	P::html do
    P::head do
      P::stylesheet
    end +
		P::body do
			if load_status[:done]
				"All #{P::link("songs", url: db.url)} loaded!"
			else
				P::goto_page(delay: "3", url: request.path_info) +"Loading...<br/>#{load_status[:songs_loaded]} #{P::link("songs", url: db.url)} loaded of #{load_status[:songs_found]} found"
			end
		end
	end
end

get '/music' do
	P::html do
    P::head do
      P::stylesheet
    end +
		P::body do
			P::link("Up", url: "/") + " "+
			P::shuffle_link(current_url: request.path_info)+
			P::unordered_list do
				db.artists.map do |artist|
					P::list_item do
						P::link(artist.name, url: artist.url)
					end
				end.join
			end
		end
	end
end

get %r{\/music\/(?:([^\/]+)\/)?(?:([^\/]+)\/)?(?:([^\/]+)\/)?shuffle} do |artist_name, album_name, song_name|
	artist_name = URI.decode_www_form_component(artist_name) unless artist_name.nil?
	album_name = URI.decode_www_form_component(album_name) unless album_name.nil?
	song_name = URI.decode_www_form_component(song_name) unless song_name.nil?
	track = db.songs(artist_name: artist_name, album_name: album_name, song_name: song_name).sample
  artist = db.find(table: :artists, key: :id, value: track.artist_id)
  album = db.find(table: :albums, key: :id, value: track.album_id)
	P::html do
    P::head do
      P::stylesheet
    end +
		P::body(style: "now-playing") do
			P::link("Up", url: db.url(artist: artist_name, album: album_name)) + " "+
			P::goto_page(delay: track.duration, url: get_shuffle_url(current_url: request.path_info)) +
			P::shuffle_link(content: "Skip", current_url: request.path_info) + " Now playing " +
			P::link(artist.name, url: artist.url) + " - " +
			P::link(track.name, url: track.url) +
			"("+P::link(album.name, url: album.url)+")" +
			P::play_audiostream(url: track.url)
		end
	end
end

get '/music/:artist' do |artist_name|
	P::html do
    P::head do
      P::stylesheet
    end +
		P::body do
			P::heading(URI.decode_www_form_component(artist_name)) +
			P::link("Up", url: db.url) + " "+
			P::shuffle_link(current_url: request.path_info)+
			P::unordered_list do
				db.albums(artist_name: URI.decode_www_form_component(artist_name)).map do |album|
					P::list_item do
						P::link(album.name, url: album.url)
					end
				end.join
			end
		end
	end
end

get '/music/:artist/:album' do |artist_name, album_name|
	P::html do
    P::head do
      P::stylesheet
    end +
		P::body do
			P::heading(URI.decode_www_form_component(album_name)) +
			P::heading(URI.decode_www_form_component(artist_name), level: 2) +
			P::link("Up", url: db.url(artist: artist_name)) + " "+
			P::shuffle_link(current_url: request.path_info)+
			P::unordered_list do
				db.songs(artist_name: URI.decode_www_form_component(artist_name), album_name: URI.decode_www_form_component(album_name)).map do |song|
					P::list_item do
						P::link(song.name, url: song.url)
					end
				end.join
			end
		end
	end
end

get '/music/:artist/:album/:song' do |artist_name, album_name, song_name|
	song = db.songs(artist_name: URI.decode_www_form_component(artist_name), album_name: URI.decode_www_form_component(album_name), song_name: URI.decode_www_form_component(song_name)).first
	send_file song.path
end

get '/style.css' do
  send_file "style.css"
end
