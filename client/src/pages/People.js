// @flow

import { ListTable } from '@performant-software/semantic-components';
import React, { type AbstractComponent } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import PeopleService from '../services/People';
import useParams from '../hooks/ParsedParams';

const People: AbstractComponent<any> = () => {
  const navigate = useNavigate();
  const { projectModelId } = useParams();
  const { t } = useTranslation();

  return (
    <ListTable
      actions={[{
        name: 'edit',
        onClick: (person) => navigate(`${person.id}`)
      }, {
        name: 'delete'
      }]}
      addButton={{
        location: 'top',
        onClick: () => navigate('new')
      }}
      collectionName='people'
      columns={[{
        name: 'last_name',
        label: t('People.columns.lastName'),
        sortable: true
      }, {
        name: 'first_name',
        label: t('People.columns.firstName'),
        sortable: true
      }]}
      onDelete={(place) => PeopleService.delete(place)}
      onLoad={(params) => PeopleService.fetchAll({
        ...params,
        project_model_id: projectModelId,
        defineable_id: projectModelId,
        defineable_type: 'CoreDataConnector::ProjectModel'
      })}
      searchable
    />
  );
};

export default People;
