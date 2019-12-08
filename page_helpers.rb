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

module P
	def self.call_if_callable(callable)
		if (callable.methods.include?(:call))
			callable.call
		else
			callable
		end
	end

	def self.stylesheet
		"<link rel=\"stylesheet\" type=\"text/css\" href=\"/style.css\">"
	end

	def self.heading(content, level: 1)
		"<h#{level}>#{content}</h#{level}>"
	end

	def self.link(content, url:)
		"<a href=\"#{url}\">#{content}</a>"
	end

	def self.html(&block)
		"<html>#{call_if_callable(yield)}</html>"
	end

	def self.body(style: nil,&block)
		"<body class=\"#{style}\">#{call_if_callable(yield)}</body>"
	end

	def self.head(&block)
		"<head>#{call_if_callable(yield)}</head>"
	end

	def self.unordered_list(&block)
		"<ul>#{call_if_callable(yield)}</ul>"
	end

	def self.list_item(&block)
		"<li>#{call_if_callable(yield)}</li>"
	end

	def self.shuffle_link(content: "Shuffle", current_url:)
		link(content, url: get_shuffle_url(current_url: current_url))
	end

	def self.goto_page(delay:, url:)
		"<meta http-equiv=\"refresh\" content=\"#{delay}; url=#{url}\" />"
	end

	def self.play_audiostream(url:)
		"<audio autoplay>
			<source src=\"#{url}\">
		</audio>"
	end
end
