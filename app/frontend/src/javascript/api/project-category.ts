import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ProjectCategory } from '../models/project-category';

export default class ProjectCategoryAPI {
  static async index (): Promise<Array<ProjectCategory>> {
    const res: AxiosResponse<Array<ProjectCategory>> = await apiClient.get('/api/project_categories');
    return res?.data;
  }

  static async create (newProjectCategory: ProjectCategory): Promise<ProjectCategory> {
    const res: AxiosResponse<ProjectCategory> = await apiClient.post('/api/project_categories', { project_category: newProjectCategory });
    return res?.data;
  }

  static async update (updatedProjectCategory: ProjectCategory): Promise<ProjectCategory> {
    const res: AxiosResponse<ProjectCategory> = await apiClient.patch(`/api/project_categories/${updatedProjectCategory.id}`, { project_category: updatedProjectCategory });
    return res?.data;
  }

  static async destroy (projectCategoryId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/project_categories/${projectCategoryId}`);
    return res?.data;
  }
}
