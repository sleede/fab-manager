import { IModule } from "angular";

export interface IApplication {
    Components: IModule,
    Services: IModule,
    Controllers: IModule,
    Filters: IModule,
    Directives: IModule
}
