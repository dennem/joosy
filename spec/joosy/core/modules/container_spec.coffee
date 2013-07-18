describe "Joosy.Modules.Container", ->

  beforeEach ->
    @seedGround()

    class @TestContainer extends Joosy.Module
      @include Joosy.Modules.Container
      @mapElements
        posts: '.post'
        content:
          post1: '#post1'
          post2: '#post2'
        footer: '.footer'
      @mapEvents
        'test': 'onContainerTest'
      container: $('#application', @ground)

    @box = new @TestContainer()

  it "reinitializes container", ->
    oldContainer = @box.container
    parent       = oldContainer.parent()
    callback     = sinon.spy()

    oldContainer.bind 'test', callback
    oldContainer.trigger 'test'
    expect(callback.callCount).toEqual 1

    newContainer = Joosy.Modules.Container.swapContainer oldContainer, 'new content'
    newContainer.trigger 'test'
    expect(newContainer.html()).toEqual 'new content'
    expect(newContainer.parent().get(0)).toBe parent.get 0
    expect(callback.callCount).toEqual 1

  describe "elements", ->
    it "declares", ->
      class SubContainerA extends @TestContainer
        @mapElements
          first: 'first'
          second: 'second'
      class SubContainerB extends SubContainerA
        @mapElements
          first: 'overrided'
          third: 'third'

      expect((new SubContainerB()).__elements).toEqual Object.extended
        posts: '.post'
        content: 
          post1: '#post1'
          post2: '#post2'
        first: 'overrided'
        second: 'second'
        third: 'third'
        footer: '.footer'

      expect((new @TestContainer()).__elements).toEqual Object.extended
        posts: '.post'
        footer: '.footer'
        content: 
          post1: '#post1'
          post2: '#post2'

      console.log (new @TestContainer)

    it "resolve selector", ->
      @box.__assignElements()

      target = @box.__extractSelector '$footer'
      expect(target).toEqual '.footer'

      target = @box.__extractSelector '$content.$post1'
      expect(target).toEqual '#post1'

      target = @box.__extractSelector '$footer tr'
      expect(target).toEqual '.footer tr'

      target = @box.__extractSelector '$footer $content.$post1'
      expect(target).toEqual '.footer #post1'

    it "nesteds get assigned", ->
      @box.__assignElements()
      expect(@box.$content.$post1().get 0).toBe $('#post1').get 0

    it "get assigned", ->
      @box.__assignElements()

      target = @box.$footer().get 0
      expect(target).toBeTruthy()
      expect(target).toBe $('.footer', @box.container).get 0
      expect(target).toBe @box.$('.footer').get 0

    it "allow to filter", ->
      @box.__assignElements()

      target = @box.$posts('#post1').get 0
      expect(target).toBeTruthy()
      expect(target).toBe $('#post1', @box.container).get 0

    it "respect container boundaries", ->
      @box.__assignElements()

      @ground.prepend('<div class="footer" />')  # out of container
      target = @box.$footer().get 0
      expect(target).toBeTruthy()
      expect(target).toBe $('.footer', @box.container).get 0
      expect(target).toBe @box.$('.footer').get 0

  describe "events", ->
    it "declares", ->
      class SubContainerA extends @TestContainer
        @mapEvents
          'test .post': 'callback2'
          'custom' : 'method'
      class SubContainerB extends SubContainerA
        @mapEvents
          'test $footer': 'onFooterTest'
          'custom' : 'overrided'
      target = (new SubContainerB()).__events
      expect(target).toEqual Object.extended
        'test': 'onContainerTest'
        'test .post': 'callback2'
        'test $footer': 'onFooterTest'
        'custom' : 'overrided'
      target = (new @TestContainer()).__events
      expect(target).toEqual Object.extended('test': 'onContainerTest')

    it "delegate", ->
      @box.__assignElements()
      callbacks = 1.upto(3).map -> sinon.spy()
      @box.__events = Object.extended(@box.__events).merge
        'test .post': callbacks[2]
        'test $footer': 'onFooterTest'

      @box.onContainerTest = callbacks[0]
      @box.onFooterTest = callbacks[1]
      @box.__delegateEvents()
      @box.container.trigger 'test'
      $('.footer', @box.container).trigger 'test'
      $('.post', @box.container).trigger 'test'
      expect(callbacks[0].callCount).toEqual 5
      expect(callbacks[1].callCount).toEqual 1
      expect(callbacks[2].callCount).toEqual 3