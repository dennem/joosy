describe "Joosy.Page", ->

  describe "manager", ->

    beforeEach ->
      @Layout = class Layout extends Joosy.Layout

      class @Page extends Joosy.Page
        @layout Layout

      sinon.stub @Page.prototype, '__bootstrap'

    afterEach ->
      @Page::__bootstrap.restore()

    it "has appropriate accessors", ->
      @Page.scroll '#here'
      expect(@Page::__scrollElement).toEqual '#here'
      expect(@Page::__scrollSpeed).toEqual 500
      expect(@Page::__scrollMargin).toEqual 0

      @Page.scroll '#there', speed: 1000, margin: -5
      expect(@Page::__scrollElement).toEqual '#there'
      expect(@Page::__scrollSpeed).toEqual 1000
      expect(@Page::__scrollMargin).toEqual -5

      @Page.layout 'test'
      expect(@Page::__layoutClass).toEqual 'test'

    it "integrates with Router", ->
      target = sinon.stub Joosy.Router, 'navigate'
      (new @Page $('#application')).navigate 'there'
      expect(target.callCount).toEqual 1
      expect(target.alwaysCalledWithExactly 'there').toBeTruthy()
      Joosy.Router.navigate.restore()

    it "respects beforeFilters cancelation", ->
      sinon.stub @Page.prototype, '__runBeforeLoads'
      @Page::__runBeforeLoads.returns(false)

      new @Page $('#application')

      expect(@Page::__bootstrap.callCount).toEqual 0

    it "loads", ->
      page = new @Page $('#application')

      spies = ['__assignElements', '__delegateEvents', '__setupWidgets', '__runAfterLoads'].map (x) ->
        sinon.spy page, x
      page.__load()
      expect(spies).toBeSequenced()

    it "unloads", ->
      page = new @Page $('#application')

      spies = ['__clearTime', '__unloadWidgets', '__removeMetamorphs', '__runAfterUnloads'].map (x) ->
        sinon.spy page, x
      page.__unload()
      expect(spies).toBeSequenced()


    describe "layout switcher", ->

      beforeEach ->
        @page = new @Page $('#application')
        @page.layout = new @Layout $('#application')

      it "does not render when previous layout is the same", ->
        new @Page $('#application'), {}, @page

        expect(@Page::__bootstrap.callCount).toEqual 2

      it "renders when previous layout is another class", ->
        class Layout extends Joosy.Layout
        class Page extends Joosy.Page
          @layout Layout

        sinon.stub Page.prototype, '__bootstrap'

        new Page $('#application'), {}, @page

        expect(@Page::__bootstrap.callCount).toEqual 1
        expect(Page::__bootstrap.callCount).toEqual 1

      describe 'when layout is not specified', ->
        beforeEach ->
          class @NoLayoutPage extends Joosy.Page

        afterEach ->
          window.ApplicationLayout = null

        it "sets default layout if there is one", ->
          window.ApplicationLayout = @Layout
          page = new @NoLayoutPage $('#application')
          expect(page.layout).toEqual jasmine.any(window.ApplicationLayout)

        it "sets no layout if default layot is unavailable", ->
          window.ApplicationLayout = null
          page = new @NoLayoutPage $('#application')
          expect(page.layout).toBeNull()

      describe 'paint callbacks', ->
        beforeEach ->
          @spies = spies = {}

          for term in ['page', 'layout']
            for filter in ['paint', 'beforePaint', 'erase', 'fetch']
              spies[term+'/'+filter] = sinon.spy()

          CallbackLayout = class @CallbackLayout extends Joosy.Layout
            @paint (container, page, done) -> spies['layout/paint'](); done()
            @beforePaint (container, page, done) -> spies['layout/beforePaint'](); done()
            @erase (container, page, done) -> spies['layout/erase'](); done()
            @fetch (done) -> spies['layout/fetch'](); done()

          class @CallbackPage extends Joosy.Page
            @layout CallbackLayout

            @paint (container, done) -> spies['page/paint'](); done()
            @beforePaint (container, done) -> spies['page/beforePaint'](); done()
            @erase (container, done) -> spies['page/erase'](); done()
            @fetch (done) -> spies['page/fetch'](); done()

        it 'get called', ->
          oldPage = new @CallbackPage $('#application')

          ['paint', 'beforePaint'].each (filter) =>
            expect(@spies["layout/#{filter}"].callCount).toEqual 1
            expect(@spies["page/#{filter}"].callCount).toEqual 0

          expect(@spies['page/fetch'].callCount).toEqual 1
          expect(@spies['layout/fetch'].callCount).toEqual 1
          expect(@spies['page/erase'].callCount).toEqual 0
          expect(@spies['layout/erase'].callCount).toEqual 0

          newPage = new @CallbackPage $('#application'), {}, oldPage

          ['paint', 'beforePaint'].each (filter) =>
            expect(@spies["layout/#{filter}"].callCount).toEqual 1
            expect(@spies["page/#{filter}"].callCount).toEqual 1

          expect(@spies['page/fetch'].callCount).toEqual 2
          expect(@spies['layout/fetch'].callCount).toEqual 1
          expect(@spies['page/erase'].callCount).toEqual 1
          expect(@spies['layout/erase'].callCount).toEqual 0

  describe "rendering", ->

    beforeEach ->
      # We test every module separately so there's no need to run all those
      sinon.stub Joosy.Page.prototype, '__load'
      sinon.stub Joosy.Page.prototype, '__unload'
      sinon.stub Joosy.Layout.prototype, '__load'
      sinon.stub Joosy.Layout.prototype, '__unload'

    afterEach ->
      Joosy.Page::__load.restore()
      Joosy.Page::__unload.restore()
      Joosy.Layout::__load.restore()
      Joosy.Layout::__unload.restore()

    it "renders", ->
      class Layout extends Joosy.Layout
        @view (locals) -> locals.page 'div', class: 'layout'

      class Page extends Joosy.Page
        @layout Layout
        @view (locals) -> 'page'

      page = new Page @$ground
      expect(@$ground.html()).toBeTag 'div', 'page', class: 'layout', id: /__joosy\d+/

    it "changes page", ->
      class Layout extends Joosy.Layout
        @view (locals) -> locals.page 'div'

      class PageA extends Joosy.Page
        @layout Layout
        @view (locals) -> 'page a'

      class PageB extends Joosy.Page
        @layout Layout
        @view (locals) -> 'page b'

      page = new PageA @$ground
      expect(@$ground.html()).toBeTag 'div', 'page a', id: /__joosy\d+/

      page = new PageB @$ground, {}, page
      expect(@$ground.html()).toBeTag 'div', 'page b', id: /__joosy\d+/

    it "changes layout", ->
      class LayoutA extends Joosy.Layout
        @view (locals) -> locals.page 'div'

      class PageA extends Joosy.Page
        @layout LayoutA
        @view (locals) -> ''

      class LayoutB extends Joosy.Layout
        @view (locals) -> locals.page 'div'

      class PageB extends Joosy.Page
        @layout LayoutB
        @view (locals) -> ''

      page = new PageA @$ground
      html = @$ground.html()
      expect(html).toBeTag 'div', '', id: /__joosy\d+/

      page = new PageB @$ground, {}, page
      expect(@$ground.html()).toBeTag 'div', '', id: /__joosy\d+/
      expect(@$ground.html()).not.toEqual html

    it "proxies @params to layout", ->
      class Layout extends Joosy.Layout
        @view (locals) -> locals.page 'div', class: 'layout'

        constructor: ->
          super arguments...
          expect(@params).toEqual foo: 'bar'


      class Page extends Joosy.Page
        @layout Layout
        @view (locals) -> 'page'

      page = new Page $('#application'), foo: 'bar'

    it "passes @data to @view", ->
      class Layout extends Joosy.Layout
        @fetch (complete) ->
          expect(@data).toEqual {}
          @data.foo = 'bar'
          complete()

        @view (locals) ->
          expect(locals.foo).toEqual 'bar'

      class Page extends Joosy.Page
        @layout Layout

        @fetch (complete) ->
          expect(@data).toEqual {}
          @data.foo = 'bar'
          complete()

        @view (locals) ->
          expect(locals.foo).toEqual 'bar'

      page = new Page $('#application')

    it "hooks", ->
      spies = []
      11.times -> spies.push sinon.spy()

      class Layout extends Joosy.Layout
        @beforePaint (container, page, complete) -> spies[0](); complete()
        @fetch       (complete)                  -> spies[1](); complete()
        @paint       (container, page, complete) -> spies[3](); complete()

        @view spies[4]

      class PageA extends Joosy.Page
        @layout Layout

        @fetch       (complete)            -> spies[2](); complete()
        @erase       (container, complete) -> spies[6](); complete()
        @view spies[5]

      class PageB extends Joosy.Page
        @layout Layout

        @beforePaint (container, complete) -> spies[7](); complete()
        @fetch       (complete)            -> spies[8](); complete()
        @paint       (container, complete) -> spies[9](); complete()

        @view spies[10]

      page = new PageA $('#application')
      page = new PageB $('#application'), {}, page

      expect(spies).toBeSequenced()
