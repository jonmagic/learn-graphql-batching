require "graphql/batch"

class Base
  def self.where(id:)
    puts "Loading #{self.name} ids: #{id}"
    Array(id).map { |_id| new(_id) }
  end

  def initialize(id)
    @id = id
  end

  attr_reader :id

  def to_s
    "<#{self.class.name} id=#{id}>"
  end
end

class Foo < Base
end

class Bar < Base
end

class Baz < Base
end

class RecordLoader < GraphQL::Batch::Loader
  def initialize(model)
    @model = model
  end

  def perform(ids)
    @model.where(id: ids).each { |record| fulfill(record.id, record) }
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end

GraphQL::Batch.batch do
  Promise.all([
    RecordLoader.for(Foo).load(1).then do |foo|
      RecordLoader.for(Bar).load(foo.id).then do |bar|
        RecordLoader.for(Baz).load(bar.id).then do |baz|
          puts foo, bar, baz
        end
      end
    end,
    RecordLoader.for(Foo).load(2).then do |foo|
      RecordLoader.for(Bar).load(foo.id).then do |bar|
        RecordLoader.for(Baz).load(bar.id).then do |baz|
          puts foo, bar, baz
        end
      end
    end
  ]).sync
end
