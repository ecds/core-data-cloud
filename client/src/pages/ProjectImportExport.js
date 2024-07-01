// @flow

import { FileInputButton, Toaster } from '@performant-software/semantic-components';
import cx from 'classnames';
import React, { useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  BsArrowBarDown,
  BsArrowBarUp,
  BsDatabaseFillDown,
  BsDatabaseFillUp
} from 'react-icons/bs';
import { FaCode } from 'react-icons/fa';
import {
  Button,
  Container,
  Header,
  Icon,
  Message,
  MessageHeader,
  Segment,
  SegmentGroup
} from 'semantic-ui-react';
import _ from 'underscore';
import FileUtils from '../utils/File';
import PermissionsService from '../services/Permissions';
import ProjectSettingsMenu from '../components/ProjectSettingsMenu';
import ProjectsService from '../services/Projects';
import styles from './ProjectImportExport.module.css';
import useParams from '../hooks/ParsedParams';

const DEFAULT_FILENAME = 'project-settings.json';

const ProjectImportExport = () => {
  const [importConfiguration, setImportConfiguration] = useState(false);
  const [exportConfiguration, setExportConfiguration] = useState(false);
  const [exportData, setExportData] = useState(false);
  const [exportVariables, setExportVariables] = useState(false);
  const [importData, setImportData] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);

  const { projectId } = useParams();
  const { t } = useTranslation();

  /**
   * Transforms the passed data into a string.
   *
   * @type {function({data: *}): *}
   */
  const transformVariables = useCallback(({ data }) => data.project?.join('\n'), []);

  /**
   * Returns the filename for the "content-disposition" header for the passed response.
   *
   * @type {function({headers: *}): *}
   */
  const getFilename = useCallback(({ headers }) => {
    let filename;

    const header = headers['content-disposition'];

    if (header) {
      filename = header
        .split(';')
        .find((name) => name.includes('filename='))
        .replace('filename=', '')
        .replaceAll('"', '')
        .trim();
    }

    return filename;
  }, []);

  /**
   * Converts the data in the passed response to a blob, creates a temporary anchor element, and downloads the file.
   *
   * @type {(function(*): void)|*}
   */
  const onDownloadData = useCallback((response) => {
    const url = URL.createObjectURL(new Blob([response.data], { type: 'application/zip' }));
    const filename = getFilename(response);

    const link = document.createElement('a');
    link.href = url;
    link.download = filename;

    const clickHandler = () => setTimeout(() => URL.revokeObjectURL(url), 150);
    link.addEventListener('click', clickHandler, false);

    link.click();
  }, []);

  /**
   * Calls the export configuration API endpoint and downloads the resulting file.
   *
   * @type {(function(): void)|*}
   */
  const onExportConfiguration = useCallback(() => {
    setExportConfiguration(true);

    ProjectsService
      .exportConfiguration(projectId)
      .then(({ data }) => FileUtils.downloadJSON(data.project, DEFAULT_FILENAME))
      .finally(() => setExportConfiguration(false));
  }, [projectId]);

  /**
   * Sets the error for the export API on the state.
   *
   * @type {(function({response: {data: *}}): void)|*}
   */
  const onExportError = useCallback(({ response: { data } }) => {
    const { errors } = JSON.parse(new TextDecoder().decode(data));

    setError({
      content: _.first(errors),
      header: t('ProjectImportExport.errors.export.header')
    });
  }, []);

  /**
   * Calls the /projects/:id/export_data API endpoint.
   *
   * @type {(function(): void)|*}
   */
  const onExportData = useCallback(() => {
    setExportData(true);

    ProjectsService
      .exportData(projectId)
      .then(onDownloadData)
      .catch(onExportError)
      .finally(() => setExportData(false));
  }, [onExportError, projectId]);

  /**
   * Calls the export variables API endpoint and opens the content in a new window.
   *
   * @type {(function(): void)|*}
   */
  const onExportVariables = useCallback(() => {
    setExportVariables(true);

    ProjectsService
      .exportVariables(projectId)
      .then(transformVariables)
      .then((data) => FileUtils.openText(data))
      .finally(() => setExportVariables(false));
  }, [projectId, transformVariables]);

  /**
   * Sets the passed import error on the state.
   *
   * @type {(function({response: {data: {errors: *}}}): void)|*}
   */
  const onImportError = useCallback(({ response: { data: { errors } } }) => {
    let content;

    if (_.has(_.first(errors), 'base')) {
      content = _.first(errors)?.base;
    } else if (_.isString(_.first(errors))) {
      content = _.first(errors);
    }

    setError({
      content,
      header: t('ProjectImportExport.errors.import.header')
    });
  }, []);

  /**
   * Calls the import configuration API endpoint and sets the success/error state.
   *
   * @type {(function([*]): void)|*}
   */
  const onImportConfiguration = useCallback(([file]) => {
    setImportConfiguration(true);

    ProjectsService
      .importConfiguration(projectId, file)
      .then(() => setSuccess(true))
      .catch(onImportError)
      .finally(() => setImportConfiguration(false));
  }, [onImportError, projectId]);

  /**
   * Calls the import data API endpoint and sets the success/error state.
   *
   * @type {(function([*]): void)|*}
   */
  const onImportData = useCallback(([file]) => {
    setImportData(true);

    ProjectsService
      .importData(projectId, file)
      .then(() => setSuccess(true))
      .catch(onImportError)
      .finally(() => setImportData(false));
  }, [onImportError, projectId]);

  return (
    <Container
      className={styles.projectImport}
      fluid
    >
      <ProjectSettingsMenu />
      <Header
        content={t('ProjectImportExport.labels.configuration')}
      />
      <SegmentGroup
        className={cx(styles.ui, styles.segments)}
      >
        <Segment
          as={Button}
          className={cx(styles.ui, styles.segment)}
          loading={exportConfiguration}
          onClick={onExportConfiguration}
          padded
        >
          <Header
            content={t('ProjectImportExport.actions.configuration.export.header')}
            icon={(
              <Icon>
                <BsArrowBarUp />
              </Icon>
            )}
            size='small'
            subheader={t('ProjectImportExport.actions.configuration.export.content')}
          />
        </Segment>
        <Segment
          as={FileInputButton}
          className={cx(styles.ui, styles.segment)}
          loading={importConfiguration}
          padded
          onSelection={onImportConfiguration}
        >
          <Header
            content={t('ProjectImportExport.actions.configuration.import.header')}
            icon={(
              <Icon>
                <BsArrowBarDown />
              </Icon>
            )}
            size='small'
            subheader={t('ProjectImportExport.actions.configuration.import.content')}
          />
        </Segment>
      </SegmentGroup>
      { (PermissionsService.canImportData() || PermissionsService.canExportData()) && (
        <>
          <Header
            content={t('ProjectImportExport.labels.data')}
          />
          <SegmentGroup
            className={cx(styles.ui, styles.segments)}
          >
            { PermissionsService.canExportData() && (
              <Segment
                as={Button}
                className={cx(styles.ui, styles.segment)}
                loading={exportData}
                onClick={onExportData}
                padded
              >
                <Header
                  content={t('ProjectImportExport.actions.data.export.header')}
                  icon={(
                    <Icon>
                      <BsDatabaseFillUp />
                    </Icon>
                  )}
                  size='small'
                  subheader={t('ProjectImportExport.actions.data.export.content')}
                />
              </Segment>
            )}
            { PermissionsService.canImportData() && (
              <Segment
                as={FileInputButton}
                className={cx(styles.ui, styles.segment)}
                loading={importData}
                onSelection={onImportData}
                padded
              >
                <Header
                  content={t('ProjectImportExport.actions.data.import.header')}
                  icon={(
                    <Icon>
                      <BsDatabaseFillDown />
                    </Icon>
                  )}
                  size='small'
                  subheader={t('ProjectImportExport.actions.data.import.content')}
                />
              </Segment>
            )}
          </SegmentGroup>
        </>
      )}
      <Header
        content={t('ProjectImportExport.labels.developer')}
      />
      <SegmentGroup
        className={cx(styles.ui, styles.segments)}
      >
        <Segment
          as={Button}
          className={cx(styles.ui, styles.segment)}
          loading={exportVariables}
          onClick={onExportVariables}
          padded
        >
          <Header
            content={t('ProjectImportExport.actions.developer.variables.header')}
            icon={(
              <Icon>
                <FaCode />
              </Icon>
            )}
            size='small'
            subheader={t('ProjectImportExport.actions.developer.variables.content')}
          />
        </Segment>
      </SegmentGroup>
      { error && (
        <Toaster
          onDismiss={() => setError(null)}
          type='negative'
        >
          <MessageHeader
            content={error.header}
          />
          <p>{ error.content }</p>
        </Toaster>
      )}
      { success && (
        <Toaster
          onDismiss={() => setSuccess(false)}
          type='positive'
        >
          <Message.Header
            content={t('ProjectImportExport.messages.import.header')}
          />
          <p>{ t('ProjectImportExport.messages.import.content') }</p>
        </Toaster>
      )}
    </Container>
  );
};

export default ProjectImportExport;
