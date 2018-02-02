import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import StatusListContainer from '../../ui/containers/status_list_container';
import {
  refreshCommunityTimeline,
  expandCommunityTimeline,
} from '../../../actions/timelines';
import Column from '../../../components/column';
import ColumnHeader from '../../../components/column_header';
import { defineMessages, injectIntl } from 'react-intl';

const messages = defineMessages({
  title: { id: 'column.community', defaultMessage: 'A look inside...' },
});

@connect()
@injectIntl
export default class CommunityTimeline extends React.PureComponent {

  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    intl: PropTypes.object.isRequired,
  };

  handleHeaderClick = () => {
    this.column.scrollTop();
  }

  setRef = c => {
    this.column = c;
  }

  componentDidMount () {
    const { dispatch } = this.props;

    dispatch(refreshCommunityTimeline());

    this.polling = setInterval(() => {
      dispatch(refreshCommunityTimeline());
    }, 3000);
  }

  componentWillUnmount () {
    if (typeof this.polling !== 'undefined') {
      clearInterval(this.polling);
      this.polling = null;
    }
  }

  handleLoadMore = () => {
    this.props.dispatch(expandCommunityTimeline());
  }

  render () {
    const { intl } = this.props;

    return (
      <Column ref={this.setRef}>
        <ColumnHeader
          icon='users'
          title={intl.formatMessage(messages.title)}
          onClick={this.handleHeaderClick}
        />

        <StatusListContainer
          timelineId='community'
          loadMore={this.handleLoadMore}
          scrollKey='standalone_community_timeline'
          trackScroll={false}
        />
      </Column>
    );
  }

}
