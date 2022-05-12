import React from 'react';

interface ErrorBoundaryState {
  hasError: boolean;
}

/**
 * This component will catch javascript errors anywhere in their child component tree and display a message to the user.
 * @see https://reactjs.org/docs/error-boundaries.html
 */
export class ErrorBoundary extends React.Component<unknown, ErrorBoundaryState> {
  constructor (props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError () {
    return { hasError: true };
  }

  componentDidCatch (error, errorInfo) {
    console.error(error, errorInfo);
  }

  render () {
    if (this.state.hasError) {
      return <h1>Something went wrong.</h1>;
    }

    return this.props.children;
  }
}
