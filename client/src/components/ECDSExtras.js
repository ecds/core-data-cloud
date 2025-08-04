// @flow

import React from 'react';
import { Icon, Button } from 'semantic-ui-react';
import { mapStyle, satelliteStyle } from '../constants/MapStyles';
import cx from 'classnames';
import styles from './ECDSExtras.module.css';

type Props = {
  baseStyle: mapStyle | satelliteStyle,
  setBaseStyle: React.Dispatch<React.SetStateAction<mapStyle | satelliteStyle>>
}

export const MapStyleSwitcher = ({ baseStyle, setBaseStyle }: Props) => {
  const updateBaseStyle = () => {
    setBaseStyle(baseStyle === mapStyle ? satelliteStyle : mapStyle);
  };

  return (
    <Button
      className={cx(
        'mapbox-gl-draw_ctrl-draw-btn',
        'layer-button',
        'icon',
        styles.ui,
        styles.button,
        styles.styleButton
      )}
      color='white'
      onClick={updateBaseStyle}
    >
      <Icon name={baseStyle === mapStyle ? 'camera' : 'map'} />
    </Button>
  );
};


export const BearingInput = ({ map }) => {
  return (
    <input
      value={`Bearing:   ${Math.floor(map?.getBearing() ?? 0)}`}
      name="bearing"
      disabled
    ></input>
  );
};
