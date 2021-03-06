#!/usr/bin/ruby

# A basic broadcast system. Keeps track of a set of messages, inserted via
# `broadcast` requests from clients.

require_relative 'node.rb'
require 'set'

class BroadcastNode
  def initialize
    @node = Node.new
    @messages = Set.new
    @neighbors = []

    @node.on "topology" do |msg|
      @neighbors = msg[:body][:topology][@node.node_id.to_sym]
      STDERR.puts "My neighbors are #{@neighbors.inspect}"
      @node.reply! msg, {type: "topology_ok"}
    end

    @node.on "read" do |msg|
      @node.reply! msg, {type: "read_ok",
                         messages: @messages.to_a}
    end

    @node.on "broadcast" do |msg|
      m = msg[:body][:message]
      unless @messages.include? m
        @messages.add m
        STDERR.puts "messages now #{@messages}"

        # Broadcast this message to neighbors (except whoever sent it to us)
        @node.other_node_ids.each do |neighbor|
          unless neighbor == msg[:src]
            @node.rpc! neighbor, {type: "broadcast", message: m} do |res|
              # Eh, whatever
            end
          end
        end
      end
      @node.reply! msg, {type: "broadcast_ok"}
    end
  end

  def main!
    @node.main!
  end
end

BroadcastNode.new.main!
