define([
    'observable'
    'joint'
    'jquery'
    'd3'
    'underscore'
], (Observable, joint, $, d3, _) ->
  (dataO, container, options) ->
    gId = @genId

    graph = new joint.dia.Graph

    paper = new joint.dia.Paper({
        el: $(container).find(".jointgraph"),
        width: 600,
        height: 200,
        model: graph,
        gridSize: 1
    })

    grect = (n) ->
      new joint.shapes.basic.Rect({
          position: { x: 100, y: 30 },
          size: { width: 100, height: 30 },
          attrs: {
            rect: { fill: 'blue' },
            text: { text: n||'box', fill: 'white'}
          }
      })

    glink = (s, t) ->
      if (s && t)
        new joint.dia.Link({
            source: { id: s },
            target: { id: t }
        })
      else new joint.dia.Link({
        source:{x: 120, y: 50},
        target:{x: 220, y: 50}
      })

    conf = $(container).find(".configuration")
    form = $(container).find("form.configure")
    form.on("submit", (e) =>
      e.preventDefault()
      e.stopImmediatePropagation()

      newConf = form.serializeArray()
      pipeComponent = form.cell.pipeComponent
      parameters = {}
      _.each(newConf, (e) -> parameters[e.name] = e.value)
      pipeComponent.parameters = parameters
      dataO([pipeComponent])
    )
    form.find("button.remove").on("click", (e) =>
      e.preventDefault()
      e.stopImmediatePropagation()
      pipeComponent = form.cell.pipeComponent
      form.cell.remove()
      dataO([_.extend(pipeComponent, {'remove': true})])
    )
    paper.on("cell:pointerdblclick", (cellView, evt, x, y) =>
      if (cellView.model instanceof joint.shapes.basic.Rect)
        cell = cellView.model
        form.cell = cell
        conf.html("")
        _.each(cell.pipeComponent.parameters, (v,k) ->
          d = $("<div class='form-group'></div>")
          l = $("<label>"+k+"</label>")
          i = $("<input type='text'class='form-control' name='"+k+"'/>")
          i.val(v)
          d.append(l)
          d.append(i)
          conf.append(d)
        )
    )

    #graph.getLinks().on("remove", () => console.dir(arguments))


    dataO.subscribe( (newData) =>
      cells = graph.getCells()
      links = graph.getLinks()
      cellsLinks =  _.union(cells, links)

      _.each(newData,
        (d) -> if (_.isUndefined(d.remove))
          d.remove = false
      )
      toAdd = _.filter(newData, (d) => !d.remove && !_.contains(_.pluck(cellsLinks, "id"), d.id))

      _.each(newData, (u) ->
        c = _.findWhere(cellsLinks, {id: u.id})
        if (c)
          c.pipeComponent = u
      )

      addCells = _.map(toAdd, (d) =>
        if (d.tpe == "box")
          r = grect(d.name)
          r.id = d.id
          r.pipeComponent = d
          r
        else
          l = glink()
          l.id = d.id
          l.pipeComponent = d
          l.on("remove", (l) => dataO([_.extend(l.pipeComponent, {'remove': true})]))
          l
      )
      graph.addCells(addCells)
    )
)


#  NOT NEEDED... but kept here in case we need something like this: inputarea in the chart...
#    # Create a custom element.
#    # ------------------------
#    joint.shapes.html = {}
#    joint.shapes.html.Element = joint.shapes.basic.Generic.extend(_.extend({}, joint.shapes.basic.PortsModelInterface, {
#        markup: '<g class="rotatable"><g class="scalable"><rect/></g><g class="inPorts"/><g class="outPorts"/></g>',
#        portMarkup: '<g class="port<%=1%>"><circle/></g>',
#        defaults: joint.util.deepSupplement({
#            type: 'html.Element',
#            size: {width: 100, height: 80},
#            inPorts: [],
#            outPorts: [],
#            attrs: {
#                '.': {magnet: false},
#                rect: {
#                    stroke: 'none', 'fill-opacity': 0, width: 150, height: 250,
#                },
#                circle: {
#                    r: 6, #circle radius
#                    magnet: true,
#                    stroke: 'black'
#                },
#                '.inPorts circle': {fill: 'green', magnet: 'passive', type: 'input'},
#                '.outPorts circle': {fill: 'red', type: 'output'}
#            }
#        }, joint.shapes.basic.Generic.prototype.defaults),
#        getPortAttrs: (portName, index, total, selector, type) ->
#          attrs = {}
#          portClass = 'port' + index
#          portSelector = selector + '>.' + portClass
#          portCircleSelector = portSelector + '>circle'
#          attrs[portCircleSelector] = {port: {id: portName || _.uniqueId(type), type: type}}
#          attrs[portSelector] = {ref: 'rect', 'ref-y': (index + 1) * (10 / total)}
#          if (selector == '.outPorts')
#            attrs[portSelector]['ref-dx'] = 0
#          return attrs
#    }))
#
#
#    # Create a custom view for that element that displays an HTML div above it.
#    # -------------------------------------------------------------------------
#
#    joint.shapes.html.ElementView = joint.dia.ElementView.extend({
#        template: [
#            '<div class="html-element">',
#            '<button class="delete">x</button>',
#            '<span id="lbl" value="Please write here"></span>',
#            '<textarea id="txt" type="text" value="Please write here"></textarea>',
#            '</div>'
#        ].join(''),
#        initialize: () ->
#          _.bindAll(this, 'updateBox')
#          joint.dia.ElementView.prototype.initialize.apply(this, arguments)
#
#          this.$box = $(_.template(this.template)())
#          # Prevent paper from handling pointerdown.
#          this.$box.find('input,select').on('mousedown click', (evt)-> evt.stopPropagation())
#
#
#          # This is an example of reacting on the input change and storing the input data in the cell model.
#          this.$box.find('textarea').on('change', _.bind(
#            ((evt) -> this.model.set('textarea', $(evt.target).val())), this)
#          )
#          this.$box.find('.delete').on('click', _.bind(this.model.remove, this.model))
#          # Update the box position whenever the underlying model changes.
#          this.model.on('change', this.updateBox, this)
#          # Remove the box when the model gets removed from the graph.
#          this.model.on('remove', this.removeBox, this)
#
#          this.updateBox()
#
#          this.listenTo(this.model, 'process:ports', this.update)
#          joint.dia.ElementView.prototype.initialize.apply(this, arguments)
#        ,
#        render: () ->
#          joint.dia.ElementView.prototype.render.apply(this, arguments)
#          this.paper.$el.prepend(this.$box)
#          # this.paper.$el.mousemove(this.onMouseMove.bind(this)), this.paper.$el.mouseup(this.onMouseUp.bind(this))
#          this.updateBox()
#          return this
#        ,
#        renderPorts: () ->
#          $inPorts = @.$('.inPorts').empty()
#          $outPorts = @.$('.outPorts').empty()
#
#          portTemplate = _.template(this.model.portMarkup)
#
#          _.each(
#            _.filter(this.model.ports, (p) -> p.type == 'in'),
#            (port, index) -> $inPorts.append(joint.V(portTemplate({id: index, port: port})).node)
#          )
#          _.each(
#            _.filter(this.model.ports, (p) -> p.type == 'out'),
#            (port, index) -> $outPorts.append(joint.V(portTemplate({id: index, port: port})).node)
#          )
#        ,
#        update: () ->
#          # First render ports so that `attrs` can be applied to those newly created DOM elements
#          # in `ElementView.prototype.update()`.
#          this.renderPorts()
#          joint.dia.ElementView.prototype.update.apply(this, arguments)
#        ,
#        updateBox: () ->
#          # Set the position and dimension of the box so that it covers the JointJS element.
#          bbox = this.model.getBBox()
#          # Example of updating the HTML with a data stored in the cell model.
#          # paper.on('blank:pointerdown', function(evt, x, y) { this.$box.find('textarea').toBack() })
#          this.$box.find('span').text(this.model.get('textarea'))
#          this.model.on('cell:pointerclick', (evt, x, y) -> this.$box.find('textarea').toFront())
#          this.$box.css({width: bbox.width, height: bbox.height, left: bbox.x, top: bbox.y, transform: 'rotate(' + (this.model.get('angle') || 0) + 'deg)'})
#        ,
#        removeBox: (evt) ->
#          this.$box.remove()
#    })
#    el1 = new joint.shapes.html.Element({
#              position: {x: 600, y: 250},
#              size: {width: 170, height: 100},
#              inPorts: ['in'],
#              outPorts: ['out'],
#              textarea: 'Start writing'
#          })
