import { ReactNode, useEffect, useState } from 'react';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';
import * as React from 'react';
import _ from 'lodash';
import { usePrevious } from '../../lib/use-previous';

type tabId = string|number;

interface Tab {
  id: tabId,
  title: ReactNode,
  content: ReactNode,
  onSelected?: () => void,
}

interface FabTabsProps {
  tabs: Array<Tab>,
  defaultTab?: tabId,
  className?: string
}

/**
 * A wrapper around https://github.com/reactjs/react-tabs that provides the Fab-manager's theme for tabs
 */
export const FabTabs: React.FC<FabTabsProps> = ({ tabs, defaultTab, className }) => {
  const [active, setActive] = useState<Tab>(tabs.filter(Boolean).find(t => t.id === defaultTab) || tabs.filter(Boolean)[0]);
  const previousTabs = usePrevious<Tab[]>(tabs);

  useEffect(() => {
    if (!_.isEqual(previousTabs?.filter(Boolean).map(t => t.id), tabs?.filter(Boolean).map(t => t?.id))) {
      setActive(tabs.filter(Boolean).find(t => t.id === defaultTab) || tabs.filter(Boolean)[0]);
    }
  }, [tabs]);

  /**
   * Return the index of the currently selected tabs (i.e. the "active" tab)
   */
  const selectedIndex = (): number => {
    return tabs.findIndex(t => t?.id === active?.id) || 0;
  };

  /**
   * Callback triggered when the active tab is changed by the user
   */
  const onIndexSelected = (index: number) => {
    setActive(tabs[index]);
    if (typeof tabs[index].onSelected === 'function') {
      tabs[index].onSelected();
    }
  };

  return (
    <Tabs className={`fab-tabs ${className || ''}`} selectedIndex={selectedIndex()} onSelect={onIndexSelected}>
      <TabList className="tabs">
        {tabs.filter(Boolean).map((tab, index) => <Tab key={index}>{tab.title}</Tab>)}
      </TabList>
      {tabs.filter(Boolean).map((tab, index) => <TabPanel key={index}>{tab.content}</TabPanel>)}
    </Tabs>
  );
};
