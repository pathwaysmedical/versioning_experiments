import React from "react";

const Provider = React.createClass({
  getInitialState: function() {
    return this.props.store.getState();
  },
  componentWillMount: function() {
    this.props.store.subscribe(() => {
      this.setState(this.props.store.getState())
    });
  },
  render: function() {
    return(
      React.createElement(
        this.props.childKlass,
        {
          dispatch: this.props.store.dispatch,
          model: this.state
        }
      )
    );
  }
});

export default Provider;
