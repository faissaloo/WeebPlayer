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

require 'ffprober'
require 'uri'

class Song
  attr_reader :name, :duration, :path, :artist_id, :album_id, :url

  def initialize(name:, duration:, path:, artist:, album:, url:)
    @name = name
    @duration = duration
    @path = path
    @artist_id = artist.id
    @album_id = album.id
    @url = url
  end

  def id
    "#{@album_id}#{@song}"
  end
end

class Album
  attr_reader :name, :artist_id, :url

  def initialize(name:, artist:, url:)
    @name = name
    @artist_id = artist.id
    @url = url
  end

  def id
    "#{@artist_id}#{@name}"
  end
end

class Artist
  attr_reader :name, :url

  def initialize(name:, url:)
    @name = name
    @url = url
  end

  def id
    @name
  end
end

class MusicDB
	def initialize(music_path:, track_info_threads: 16)
		@db = { files: [], albums: [], artists: [], songs: [] }
		@loaded = false
		@music_path = music_path
		@track_info_threads = track_info_threads
	end

	def load_status
		{
			songs_found: @db[:files].count,
			songs_loaded: @db[:songs].count,
			done: @db[:songs].count == @db[:files].count
		}
	end

	def load_async
		Thread.new do
			load_files
			@db[:files].each_slice((@db[:files].size/@track_info_threads.to_f).round).each do |paths|
				Thread.new do
					paths.compact.each do |path|
						load_track_info(path: path)
					end
				end
			end
		end
	end

	def load_track_info(path:)
		song_info = Ffprober::Parser.from_file(path)
		tags = song_info.format.tags
		name = tags[:TITLE] || tags[:title]
		artist_name = tags[:ARTIST] || tags[:artist] || "No Artist"
		album_name = tags[:ALBUM] || tags[:album] || "No Album"
		duration = song_info.audio_streams.first.duration

    artist = find(table: :artists, key: :name, value: artist_name)
    if artist.nil?
      artist = Artist.new(name: artist_name, url: url(artist: artist_name))
      @db[:artists] << artist
    end

    album = find(table: :albums, key: :name, value: album_name)
    if album.nil?
      album = Album.new(name: album_name, artist: artist, url: url(artist: artist_name, album: album_name))
      @db[:albums] << album
    end

    @db[:songs] << Song.new(
      name: name,
      duration: duration,
      album: album,
      artist: artist,
      url: url(artist: artist_name, album: album_name, song: name),
      path: path
    )
	end

	def load_files
		@db[:files] = Dir[File.join(@music_path, '**', '*')].reject do |path|
			File.directory?(path) || !path.match?(/(?:flac|mp3|m4a)$/)
		end
	end

	def url(artist: nil, album: nil, song: nil)
		"/"+File.join(*["music", artist, album, song].compact.map do |node|
			URI.encode_www_form_component(node)
		end)
	end

  def find(table:, key:, value:)
    @db[table].find { |record| record.send(key) == value }
  end

  def songs(artist_name: nil, album_name: nil, song_name: nil)
		@db[:songs].select do |song|
			(song_name.nil? || song.name == song_name) &&
			(artist_name.nil? || find(table: :artists, key: :id, value: song.artist_id).name == artist_name) &&
			(album_name.nil? || find(table: :albums, key: :id, value: song.album_id).name == album_name)
		end
	end

	def albums(artist_name:)
    artist = find(table: :artists, key: :name, value: artist_name)

    @db[:albums].select do |album|
      album.artist_id == artist.id
    end
	end

	def artists
    @db[:artists]
	end
end
