// @flow

import { Types } from './ProjectModels';

const DEFAULT_LIMIT = 0;
const RADIX = 10;

/**
 * Returns the limit for the number of records to include in a IIIF manifest.
 *
 * @returns {number}
 */
const getManifestLimit = () => {
  let limit = DEFAULT_LIMIT;

  if (process.env.REACT_APP_IIIF_MANIFEST_ITEM_LIMIT) {
    limit = parseInt(process.env.REACT_APP_IIIF_MANIFEST_ITEM_LIMIT, RADIX);
  }

  return limit;
};

/**
 * Records the IIIF manifest URL for the passed project model, record UUID, and project model relationship UUID.
 *
 * @param projectModel
 * @param recordId
 * @param projectModelRelationshipId
 *
 * @returns {*}
 */
const getManifestURL = (projectModel, recordId, projectModelRelationshipId) => {
  let url;

  let baseUrl;

  if (projectModel.model_class_view === Types.Instance) {
    baseUrl = 'instances';
  } else if (projectModel.model_class_view === Types.Item) {
    baseUrl = 'items';
  } else if (projectModel.model_class_view === Types.Place) {
    baseUrl = 'places';
  } else if (projectModel.model_class_view === Types.Work) {
    baseUrl = 'works';
  }

  if (baseUrl) {
    url = [
      process.env.REACT_APP_HOSTNAME,
      'core_data',
      'public',
      baseUrl,
      recordId,
      'manifests',
      projectModelRelationshipId
    ].join('/');
  }

  return url;
};

export default {
  getManifestLimit,
  getManifestURL
};
