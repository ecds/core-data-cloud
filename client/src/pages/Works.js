// @flow

import React, {
  type AbstractComponent,
  useState,
  useContext
} from 'react';

import { ListTable } from '@performant-software/semantic-components';
import { Icon } from 'semantic-ui-react';
import { useTranslation } from 'react-i18next';
import { IoBulb, IoBulbOutline } from 'react-icons/io5';
import { useNavigate } from 'react-router-dom';
import ListViewMenu from '../components/ListViewMenu';
import PermissionsService from '../services/Permissions';
import ProjectContext from '../context/Project';
import useParams from '../hooks/ParsedParams';
import Views from '../constants/ListViews';
import WindowUtils from '../utils/Window';
import WorksService from '../services/Works';

const Works: AbstractComponent<any> = () => {
  const [view, setView] = useState(Views.all);

  const { projectModel } = useContext(ProjectContext);
  const navigate = useNavigate();
  const { projectModelId } = useParams();
  const { t } = useTranslation();

  return (
    <>
      <ListViewMenu
        icons={{
          all: (
            <Icon>
              <IoBulb />
            </Icon>
          ),
          owned: (
            <Icon>
              <IoBulbOutline />
            </Icon>
          )
        }}
        onChange={(value) => setView(value)}
        value={view}
      />
      <ListTable
        actions={[{
          name: 'edit',
          onClick: (work) => navigate(`${work.id}`)
        }, {
          accept: (work) => PermissionsService.canDeleteRecord(projectModel, work),
          name: 'delete'
        }]}
        addButton={{
          basic: false,
          color: 'blue',
          location: 'top',
          onClick: () => navigate('new')
        }}
        collectionName='works'
        columns={[{
          label: t('Works.columns.name'),
          name: 'core_data_connector_names.name',
          resolve: (work) => work.primary_name?.name?.name,
          sortable: true
        }, {
          name: 'uuid',
          label: t('Common.columns.uuid'),
          sortable: true,
          hidden: true
        }]}
        key={view}
        onDelete={(work) => WorksService.delete(work)}
        onLoad={(params) => (
          WorksService
            .fetchAll({
              ...params,
              project_model_id: projectModelId,
              defineable_id: projectModelId,
              defineable_type: 'CoreDataConnector::ProjectModel',
              view
            })
            .finally(() => WindowUtils.scrollToTop())
        )}
        searchable
      />
    </>
  );
};

export default Works;
