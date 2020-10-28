import Switch from 'react-switch';
import { react2angular } from 'react2angular';
import { IApplication } from '../models/application';

declare var Application: IApplication;

Application.Components.component('switch', react2angular(Switch, ['checked', 'onChange', 'id', 'className']));
