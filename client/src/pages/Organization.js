// @flow

import {
  BooleanIcon,
  EmbeddedList,
  SimpleEditPage
} from '@performant-software/semantic-components';
import type { EditContainerProps } from '@performant-software/shared-components/types';
import React, { type AbstractComponent } from 'react';
import { useTranslation } from 'react-i18next';
import { Form, Header } from 'semantic-ui-react';
import OwnableDropdown from '../components/OwnableDropdown';
import type { Organization as OrganizationType } from '../types/Organization';
import OrganizationNameModal from '../components/OrganizationNameModal';
import OrganizationService from '../services/Organizations';
import styles from './Organization.module.css';
import Validation from '../utils/Validation';
import withReactRouterEditPage from '../hooks/ReactRouterEditPage';

type Props = EditContainerProps & {
  item: OrganizationType
};

const OrganizationForm = (props: Props) => {
  const { t } = useTranslation();

  return (
    <SimpleEditPage
      {...props}
      className={styles.organization}
    >
      <SimpleEditPage.Tab
        key='default'
      >
        <Form.Input
          label={t('Common.labels.project')}
          required
        >
          <OwnableDropdown
            item={props.item}
            onSetState={props.onSetState}
          />
        </Form.Input>
        <Header
          content={t('Organization.labels.names')}
        />
        <EmbeddedList
          actions={[{
            name: 'edit'
          }, {
            name: 'delete'
          }]}
          className={styles.organizationNames}
          columns={[{
            name: 'name',
            label: t('Organization.organizationNames.columns.name')
          }, {
            name: 'primary',
            label: t('Organization.organizationNames.columns.primary'),
            render: (organizationName) => <BooleanIcon value={organizationName.primary} />
          }]}
          items={props.item.organization_names}
          modal={{
            component: OrganizationNameModal
          }}
          onSave={props.onSaveChildAssociation.bind(this, 'organization_names')}
          onDelete={props.onDeleteChildAssociation.bind(this, 'organization_names')}
        />
        <Form.TextArea
          error={props.isError('description')}
          label={t('Organization.labels.description')}
          onChange={props.onTextInputChange.bind(this, 'description')}
          required={props.isRequired('description')}
          value={props.item.description}
        />
      </SimpleEditPage.Tab>
    </SimpleEditPage>
  );
};

const Organization: AbstractComponent<any> = withReactRouterEditPage(OrganizationForm, {
  id: 'organizationId',
  onInitialize: (id) => (
    OrganizationService
      .fetchOne(id)
      .then(({ data }) => data.organization)
  ),
  onSave: (organization) => (
    OrganizationService
      .save(organization)
      .then(({ data }) => data.organization)
  ),
  resolveValidationError: Validation.resolveUpdateError.bind(this)
});

export default Organization;
